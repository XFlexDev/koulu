"""Wilma HTTP client.

Targets modern Wilma (ApiVersion ~30, the current inschool.fi builds):
/token login -> Wilma2SID cookie -> role-slugged HTML/JSON pages.
The old index_json JSON surface mostly 403s on current builds, so schedule,
exams, news etc. are parsed from the real pages. All parsing quirks live here
so the frontend only ever sees clean JSON.
"""

from __future__ import annotations

import re
from datetime import date, datetime, timedelta
from typing import Any, Optional

import httpx


class WilmaAuthError(Exception):
    pass


class WilmaAPIError(Exception):
    pass


class WilmaClient:
    def __init__(self, base_url: str):
        base = base_url.strip().rstrip("/")
        if not base.startswith("http"):
            base = "https://" + base
        self.base_url = base
        self.http = httpx.AsyncClient(
            base_url=self.base_url,
            follow_redirects=True,
            timeout=30.0,
            headers={
                "User-Agent": "koulu/1.0",
                "Accept": "application/json, text/html",
            },
        )
        self.sid: Optional[str] = None
        self.slug = ""
        self.form_key: Optional[str] = None
        self.account: dict = {}
        self.roles: list[dict] = []
        self._username: Optional[str] = None
        self._password: Optional[str] = None
        self._on_relogin = None  # callback to persist refreshed session

    # ------------------------------------------------------------------
    # auth
    # ------------------------------------------------------------------

    async def login(self, username: str, password: str) -> dict:
        """Log in and resolve account, roles and the active role slug."""
        self._username = username
        self._password = password

        # Modern Wilma: login JS fetches /token and submits its Wilma2LoginID
        # as SESSIONID. Older builds return SessionID from /index_json.
        session_id = None
        await self.http.get("/")  # primes the cookies
        try:
            tok = await self.http.get("/token")
            session_id = tok.json().get("Wilma2LoginID")
        except (ValueError, httpx.HTTPError):
            pass
        if not session_id:
            r = await self.http.get("/index_json")
            r.raise_for_status()
            try:
                session_id = r.json().get("SessionID")
            except ValueError:
                session_id = None
        if not session_id:
            raise WilmaAuthError("Wilma did not return a SessionID")

        login = await self.http.post(
            "/login",
            data={
                "Login": username,
                "Password": password,
                "SESSIONID": session_id,
                "CompleteJson": "",
                "format": "json",
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        if "loginfailed" in str(login.url).lower() or "loginfailed" in login.headers.get("Location", "").lower():
            raise WilmaAuthError("Wrong username or password")

        self.sid = self.http.cookies.get("Wilma2SID")
        if not self.sid:
            raise WilmaAuthError("Wilma did not set a session cookie")

        start_page: dict = {}
        try:
            data = login.json()
            if isinstance(data, dict) and data.get("LoginResult"):
                start_page = data
                if data.get("LoginResult") != "Ok":
                    raise WilmaAuthError("Login failed")
                self.form_key = data.get("FormKey")
        except ValueError:
            pass

        # Roles carry the URL slug (e.g. "\\!0249962") and per-role formkey.
        try:
            roles_r = await self.http.get("/api/v1/accounts/me/roles")
            if roles_r.status_code == 200:
                payload = roles_r.json().get("payload") or []
                self.roles = [
                    {
                        "name": r_.get("name", ""),
                        "type": r_.get("type", ""),
                        "id": r_.get("primusId"),
                        "slug": (r_.get("slug") or "").replace("\\", ""),
                        "form_key": r_.get("formKey"),
                        "school": r_.get("schoolName"),
                    }
                    for r_ in payload
                    if r_.get("type") != "passwd"
                ]
        except (ValueError, KeyError):
            pass

        if self.roles:
            self.slug = self.roles[0]["slug"]
            if self.roles[0].get("form_key"):
                self.form_key = self.roles[0]["form_key"]

        if not self.slug:
            m = re.search(r"(/!\d+)", str(login.url)) or re.search(
                r'href="(/!\d+)', login.text
            )
            if m:
                self.slug = m.group(1)

        try:
            me = await self.http.get("/api/v1/accounts/me")
            if me.status_code == 200:
                p = me.json().get("payload") or {}
                self.account = {
                    "id": p.get("primusId"),
                    "firstname": p.get("firstName") or p.get("firstname"),
                    "lastname": p.get("lastName") or p.get("lastname"),
                    "username": username,
                }
        except ValueError:
            pass

        if not self.account and self.roles:
            parts = self.roles[0]["name"].strip().split(" ", 1)
            self.account = {
                "id": self.roles[0]["id"],
                "firstname": parts[0],
                "lastname": parts[1] if len(parts) > 1 else "",
                "username": username,
            }
        if not self.account:
            self.account = {"username": username}

        return {
            "account": self.account,
            "roles": [
                {"name": r_["name"], "type": r_["type"], "slug": r_["slug"]}
                for r_ in self.roles
            ],
            "start_page": start_page,
        }

    def snapshot(self) -> dict:
        return {
            "base_url": self.base_url,
            "sid": self.sid,
            "slug": self.slug,
            "form_key": self.form_key,
            "account": self.account,
            "roles": self.roles,
            "username": self._username,
            "password": self._password,
        }

    async def restore(self, snap: dict) -> None:
        self.base_url = snap["base_url"]
        self.http = httpx.AsyncClient(
            base_url=self.base_url,
            follow_redirects=True,
            timeout=30.0,
            headers={"User-Agent": "koulu/1.0", "Accept": "application/json, text/html"},
            cookies={"Wilma2SID": snap.get("sid") or ""},
        )
        self.sid = snap.get("sid")
        self.slug = snap.get("slug") or ""
        self.form_key = snap.get("form_key")
        self.account = snap.get("account") or {}
        self.roles = snap.get("roles") or []
        self._username = snap.get("username")
        self._password = snap.get("password")

    async def close(self) -> None:
        await self.http.aclose()

    # ------------------------------------------------------------------
    # request plumbing
    # ------------------------------------------------------------------

    async def _request(self, method: str, path: str, retry: bool = True, **kw) -> httpx.Response:
        if path.startswith("/api/") or path.startswith("/index_json") or path.startswith("/!"):
            url = path
        else:
            url = f"{self.slug}{path}"
        r = await self.http.request(method, url, **kw)
        # Expired sessions bounce to /login; re-login once and retry.
        if retry and "/login" in str(r.url).lower() and self._username:
            self.sid = None
            self.http.cookies.clear()
            await self.login(self._username, self._password or "")
            if self._on_relogin:
                self._on_relogin()
            r = await self.http.request(method, url, **kw)
        return r

    async def _json(self, path: str, **kw) -> Any:
        r = await self._request("GET", path, **kw)
        try:
            return r.json()
        except ValueError:
            raise WilmaAPIError(f"Non-JSON response from {path} (HTTP {r.status_code})")

    @staticmethod
    def _d(d: Any) -> str:
        """Wilma stores caption-ish fields as {'0': 'text'} dicts."""
        if isinstance(d, dict):
            return str(d.get("0", ""))
        return str(d) if d is not None else ""

    @staticmethod
    def _soup(html: str):
        from bs4 import BeautifulSoup

        return BeautifulSoup(html, "html.parser")

    @staticmethod
    def _balanced(text: str, start: int) -> str:
        """Extract the [...] array starting at text[start] with bracket matching."""
        depth = 0
        in_str = False
        esc = False
        for i in range(start, len(text)):
            ch = text[i]
            if in_str:
                if esc:
                    esc = False
                elif ch == "\\":
                    esc = True
                elif ch == '"':
                    in_str = False
                continue
            if ch == '"':
                in_str = True
            elif ch == "[":
                depth += 1
            elif ch == "]":
                depth -= 1
                if depth == 0:
                    return text[start : i + 1]
        return ""

    # ------------------------------------------------------------------
    # schedule — parsed from the eventsJSON blob in /schedule?date=
    # ------------------------------------------------------------------

    async def get_schedule(self, target: Optional[date] = None) -> dict:
        target = target or date.today()
        monday = target - timedelta(days=target.weekday())
        q = f"{target.day}.{target.month}.{target.year}"
        r = await self._request("GET", f"/schedule?date={q}")
        return self._parse_schedule_html(r.text, monday)

    def _parse_schedule_html(self, html: str, monday: date) -> dict:
        import json as _json

        days: dict[int, dict] = {
            i: {
                "date": (monday + timedelta(days=i)).isoformat(),
                "weekday": i + 1,
                "lessons": [],
            }
            for i in range(7)
        }
        m = re.search(r"Events\s*:\s*\[", html)
        if m:
            arr = self._balanced(html, html.index("[", m.start()))
            try:
                events = _json.loads(arr)
            except ValueError:
                events = []
        else:
            events = []

        for ev in events:
            try:
                d = datetime.strptime(ev.get("Date", ""), "%d.%m.%Y").date()
            except (ValueError, TypeError):
                continue
            weekday = d.weekday()
            if weekday not in days:
                continue

            is_break = ev.get("Tyyppi") != "Teaching"
            long_text = self._d(ev.get("LongText"))
            code = self._d(ev.get("Text"))
            # LongText looks like "KE701 Kemia lkaste: 7" or "KE701 Kemia"
            subject = long_text
            if code and subject.startswith(code):
                subject = subject[len(code):].strip()
            subject = re.sub(r"\s*lkaste:.*$", "", subject).strip()
            if not subject:
                subject = long_text or code
            if is_break:
                subject = "Ruokailu" if code.startswith("R ") else subject or "Välitunti"

            def names(key: str) -> list[str]:
                out = []
                info = ev.get(key) or {}
                for slot in info.values():
                    for item in slot.values():
                        if isinstance(item, dict):
                            out.append(item.get("nimi") or item.get("lyhenne") or "")
                return [n for n in out if n]

            start_m = ev.get("Start")
            end_m = ev.get("End")
            fmt = lambda v: f"{int(v)//60:02d}:{int(v)%60:02d}" if isinstance(v, (int, float)) else ""

            days[weekday]["lessons"].append(
                {
                    "start": fmt(start_m),
                    "end": fmt(end_m),
                    "subject": subject,
                    "code": code,
                    "color": ev.get("Color") or "#888",
                    "room": ", ".join(names("HuoneInfo")),
                    "class": ev.get("Lk") or "",
                    "teachers": names("OpeInfo"),
                    "info": self._d(ev.get("Lisatieto")) or self._d(ev.get("Muistiinpanot")),
                    "break": is_break,
                    "raw_subject": long_text,
                }
            )
        for d in days.values():
            d["lessons"].sort(key=lambda l: l.get("start") or "")
        return {
            "week_start": monday.isoformat(),
            "week_end": (monday + timedelta(days=6)).isoformat(),
            "days": list(days.values()),
        }

    # ------------------------------------------------------------------
    # messages
    # ------------------------------------------------------------------

    _FOLDERS = {
        "inbox": "/messages/list/index_json",
        "sent": "/messages/list/outbox",
        "outbox": "/messages/list/outbox",
        "archive": "/messages/list/archive",
        "drafts": "/messages/list/drafts",
        "all": "/messages/list/all",
    }

    async def get_messages(self, folder: str = "inbox") -> list[dict]:
        path = self._FOLDERS.get(folder)
        if not path:
            raise WilmaAPIError(f"Unknown folder {folder}")
        r = await self._request("GET", path)
        try:
            data = r.json()
        except ValueError:
            raise WilmaAPIError(f"Messages unavailable (HTTP {r.status_code})")
        show_recipient = folder in ("sent", "outbox", "drafts")
        out = []
        for m in data.get("Messages") or []:
            who = (m.get("Recipient") if show_recipient else m.get("Sender")) or m.get("Sender") or m.get("Recipient") or ""
            out.append(
                {
                    "id": m.get("Id"),
                    "subject": m.get("Subject") or "(no subject)",
                    "from": who,
                    "timestamp": m.get("TimeStamp"),
                    "unread": bool(m.get("Status")),
                    "folder": m.get("Folder") or folder,
                    "replies": m.get("Replies") or 0,
                }
            )
        return out

    async def get_message(self, mid: int) -> dict:
        r = await self._request("GET", f"/messages/{mid}")
        soup = self._soup(r.text)
        subject = ""
        title = soup.find("title")
        if title:
            subject = title.get_text().rsplit(" - Wilma", 1)[0].strip()
        # breadcrumb's active item is more reliable than the title
        crumb = soup.select_one("ol.breadcrumb li.active")
        if crumb:
            subject = crumb.get_text(" ", strip=True)

        meta: dict[str, str] = {}
        for tr in soup.select("table.proptable tr"):
            cells = tr.find_all(["th", "td"])
            if len(cells) >= 2:
                label = cells[0].get_text(" ", strip=True).rstrip(":").casefold()
                if label:
                    meta[label] = cells[1].get_text(" ", strip=True)

        bodies = soup.select("div.ckeditor")
        html_body = str(bodies[0]) if bodies else ""

        # replies render as further ckeditor divs or .msg-reply blocks
        replies = []
        for div in bodies[1:]:
            replies.append({"from": "", "timestamp": "", "html": str(div)})

        allow_reply = bool(soup.find("a", href=re.compile(r"compose\?replyid=")))

        return {
            "id": mid,
            "subject": subject,
            "from": meta.get("lähettäjä", ""),
            "timestamp": meta.get("lähetetty", ""),
            "recipients": meta.get("vastaanottajat", ""),
            "html": html_body,
            "replies": replies,
            "allow_reply": allow_reply,
        }

    async def get_recipients(self) -> list[dict]:
        r = await self._request("GET", "/messages/recipients")
        soup = self._soup(r.text)
        out = []
        seen = set()
        for btn in soup.select(".recipient-block"):
            src = btn.get("data-source") or ""
            m = re.search(r"r_([a-z]+)=(\d+)", src)
            if not m:
                continue
            rtype, rid = m.group(1), m.group(2)
            name = btn.get_text(" ", strip=True)
            n_class = re.search(r"n_class=(\d+)", src)
            key = (rtype, rid, name)
            if key in seen:
                continue
            seen.add(key)
            out.append(
                {
                    "id": rid,
                    "name": name,
                    "type": rtype,
                    "n_class": n_class.group(1) if n_class else None,
                }
            )
        return out

    async def _post_compose_form(self, query: str, subject: str, body: str, send: bool = True) -> bool:
        """GET compose page, replay its hidden inputs, POST it."""
        form_r = await self._request("GET", f"/messages/compose?{query}")
        soup = self._soup(form_r.text)
        form = None
        for f in soup.find_all("form"):
            if f.find("textarea"):
                form = f
                break
        if not form:
            raise WilmaAPIError("Compose form not found")

        payload: dict[str, str] = {}
        for inp in form.find_all(["input", "textarea", "select"]):
            name = inp.get("name")
            if not name:
                continue
            if inp.name == "textarea":
                payload[name] = body
            elif name.casefold() == "subject":
                payload[name] = subject
            elif inp.get("type") == "checkbox":
                if inp.has_attr("checked") and inp.get("value"):
                    payload[name] = inp.get("value")
            elif inp.get("type") == "submit":
                if send and inp.get("value"):
                    payload[name] = inp.get("value")
            elif inp.get("value"):
                payload[name] = inp.get("value") or ""
        payload.setdefault("formkey", self.form_key or "")
        payload["BodyText"] = body
        if "Subject" in payload or not any(k.casefold() == "subject" for k in payload):
            payload["Subject"] = subject

        action = form.get("action") or "/messages/compose"
        r = await self._request("POST", action, data=payload)
        return "/compose" not in str(r.url)

    async def reply_message(self, mid: int, body: str) -> bool:
        # Replies go through the compose form with replyid + prefilled subject.
        form_r = await self._request("GET", f"/messages/compose?replyid={mid}")
        soup = self._soup(form_r.text)
        subject = ""
        subj_inp = soup.find("input", {"name": "Subject"})
        if subj_inp:
            subject = subj_inp.get("value") or ""
        return await self._post_compose_form(f"replyid={mid}", subject, body)

    async def send_message(self, recipients: list[dict], subject: str, body: str) -> bool:
        params = "&".join(
            f"r_{r['type']}={r['id']}" + (f"&n_class={r['n_class']}" if r.get("n_class") else "")
            for r in recipients
        )
        return await self._post_compose_form(params, subject, body)

    # ------------------------------------------------------------------
    # exams / news / attendance / assessments — HTML pages
    # ------------------------------------------------------------------

    async def get_exams(self) -> list[dict]:
        r = await self._request("GET", "/exams/calendar")
        soup = self._soup(r.text)
        out = []
        for table in soup.select("table.table-grey"):
            rows = table.find_all("tr")
            if not rows:
                continue
            first = rows[0].find_all("td")
            if len(first) < 2:
                continue
            when = first[0].get_text(" ", strip=True)
            subject_raw = re.sub(r"\s+", " ", first[1].get_text(" ", strip=True))
            name, _, course = subject_raw.partition(" : ")
            course_code, _, course_name = course.partition(" : ")
            extra: dict[str, str] = {}
            for tr in rows[1:]:
                cells = tr.find_all(["th", "td"])
                if len(cells) >= 2:
                    extra[cells[0].get_text(" ", strip=True).rstrip(":").casefold()] = cells[1].get_text(" ", strip=True)
            date_m = re.search(r"(\d{1,2}\.\d{1,2}\.\d{4})", when)
            time_m = re.search(r"(\d{1,2}:\d{2})", when)
            out.append(
                {
                    "date": date_m.group(1) if date_m else when,
                    "time": time_m.group(1) if time_m else None,
                    "name": name.strip(),
                    "course_code": course_code.strip() or None,
                    "course": course_name.strip() or None,
                    "teacher": extra.get("opettaja"),
                    "info": extra.get("kokeen lisätiedot"),
                }
            )
        return out

    async def get_news(self) -> list[dict]:
        r = await self._request("GET", "/news")
        soup = self._soup(r.text)
        out = []
        current_date = ""
        main = soup.select_one(".tab-content") or soup
        for el in main.find_all(["h2", "div"]):
            if el.name == "h2" and re.match(r"^\d{1,2}\.\d{1,2}\.?$", el.get_text(strip=True)):
                current_date = el.get_text(strip=True).rstrip(".")
            elif el.name == "div" and "well" in (el.get("class") or []):
                h3 = el.find("h3")
                link = el.find("a", href=re.compile(r"/news/\d+"))
                author = el.select_one("a.profile-link")
                desc = el.select_one("p.sub-text")
                nid = None
                if link:
                    nm = re.search(r"/news/(\d+)", link["href"])
                    if nm:
                        nid = int(nm.group(1))
                out.append(
                    {
                        "id": nid,
                        "title": h3.get_text(" ", strip=True) if h3 else "",
                        "date": current_date,
                        "description": desc.get_text(" ", strip=True) if desc else "",
                        "author": author.get_text(" ", strip=True) if author else "",
                        "sticky": bool(el.select_one(".vismaicon-locked")),
                        "important": bool(el.select_one(".vismaicon-info")),
                    }
                )
        return out

    async def get_news_item(self, nid: int) -> dict:
        r = await self._request("GET", f"/news/{nid}")
        soup = self._soup(r.text)
        main = soup.select_one("#main-content") or soup
        h2 = main.find("h2") or main.find("h1")
        title = h2.get_text(" ", strip=True) if h2 else ""
        # body is the largest text block after the heading
        body = ""
        well = main.select_one(".well") or main.select_one(".panel-body")
        if well:
            body = well.get_text("\n", strip=True)
        return {"id": nid, "title": title, "body": body}

    async def get_attendance(self, target: Optional[date] = None) -> dict:
        r = await self._request("GET", "/attendance")
        soup = self._soup(r.text)
        text = soup.get_text(" ", strip=True).casefold()
        obs: list[dict] = []
        if "selvitystä vaativaa tuntimerkintää" in text or "ei ole yhtään" in text:
            return {"observations": [], "allow_excuse": False, "excuses": []}
        # entries render as a table when they exist; parse generically
        for tr in soup.select("table tr"):
            cells = tr.find_all("td")
            if len(cells) < 2:
                continue
            inp = tr.find("input", {"type": "checkbox"})
            oid = None
            if inp and inp.get("name"):
                m = re.search(r"(\d+)", inp["name"])
                oid = int(m.group(1)) if m else None
            obs.append(
                {
                    "id": oid,
                    "timestamp": cells[0].get_text(" ", strip=True),
                    "type": cells[1].get_text(" ", strip=True),
                    "description": cells[2].get_text(" ", strip=True) if len(cells) > 2 else "",
                }
            )
        allow_excuse = bool(soup.find("input", {"type": "checkbox"}))
        return {"observations": obs, "allow_excuse": allow_excuse, "excuses": []}

    async def get_assessments(self) -> list[dict]:
        r = await self._request("GET", "/assessments")
        soup = self._soup(r.text)
        out = []
        for tr in soup.select("table.assessment-discussion-table tbody tr"):
            cells = tr.find_all("td")
            if len(cells) < 3:
                continue
            link = tr.find("a", href=re.compile(r"/assessments/\d+"))
            aid = None
            if link:
                m = re.search(r"/assessments/(\d+)", link["href"])
                aid = int(m.group(1)) if m else None
            out.append(
                {
                    "id": aid,
                    "start": cells[0].get_text(" ", strip=True),
                    "end": cells[1].get_text(" ", strip=True),
                }
            )
        return out

    async def save_excuse(self, obs_ids: list[int], excuse_type: int, text: str = "") -> bool:
        params: dict[str, Any] = {"formkey": self.form_key or "", "type": excuse_type, "text": text}
        for oid in obs_ids:
            params[f"item{oid}"] = "true"
        r = await self._request("POST", "/attendance/saveexcuse", data=params)
        return r.status_code in (200, 302)

    async def get_choices(self) -> list[dict]:
        try:
            data = await self._json("/api/v1/me/trays")
        except WilmaAPIError:
            return []
        return data.get("payload") or []

    async def get_me_v1(self) -> dict:
        try:
            data = await self._json("/api/v1/accounts/me")
            return data.get("payload") or {}
        except WilmaAPIError:
            return {}
