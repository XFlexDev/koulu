"""Wilma HTTP client.

Implements the undocumented JSON surface used by Wilma's own web and mobile
clients: index_json login -> Wilma2SID cookie -> /<role-slug>/...index_json
endpoints, plus the newer /api/v1 endpoints. All parsing of Wilma's quirks
lives here so the frontend only ever sees clean JSON.
"""

from __future__ import annotations

import json
import re
from datetime import date, datetime
from typing import Any, Optional

import httpx


class WilmaAuthError(Exception):
    pass


class WilmaAPIError(Exception):
    pass


_ROLE_TYPE_LABELS = {
    "student": "student",
    "teacher": "teacher",
    "guardian": "guardian",
    "personnel": "personnel",
}


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

        r = await self.http.get("/index_json")
        r.raise_for_status()
        try:
            session_id = r.json().get("SessionID")
        except ValueError:
            session_id = None
        if not session_id:
            raise WilmaAuthError("Wilma did not return a SessionID")

        login = await self.http.post(
            "/index_json",
            data={
                "Login": username,
                "Password": password,
                "SESSIONID": session_id,
                "CompleteJson": "",
                "format": "json",
            },
            headers={"Content-Type": "application/x-www-form-urlencoded"},
        )
        location = login.headers.get("Location", "")
        if "loginfailed" in location.lower():
            raise WilmaAuthError("Wrong username or password")

        self.sid = self.http.cookies.get("Wilma2SID")
        if not self.sid:
            raise WilmaAuthError("Wilma did not set a session cookie")

        # The login response body (format=json) is the user's start page:
        # LoginResult, WilmaId, FormKey, Messages, Exams, News, Groups.
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

        # Account info (newer accounts only; 403 on old ones)
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
        if path.startswith("/api/") or path.startswith("/index_json") or path.startswith("/message/"):
            url = path
        elif path.startswith("/!"):
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
            url = url if url.startswith("/!") or url.startswith("/api") or url.startswith("/index_json") or url.startswith("/message/") else f"{self.slug}{path}"
            r = await self.http.request(method, url, **kw)
        return r

    async def _json(self, path: str, **kw) -> Any:
        r = await self._request("GET", path, **kw)
        try:
            return r.json()
        except ValueError:
            # Some endpoints hand back HTML when the session lacks api perms
            raise WilmaAPIError(f"Non-JSON response from {path} (HTTP {r.status_code})")

    @staticmethod
    def _d(d: Any) -> str:
        """Wilma stores caption-ish fields as {'0': 'text'} dicts."""
        if isinstance(d, dict):
            return str(d.get("0", ""))
        return str(d) if d is not None else ""

    # ------------------------------------------------------------------
    # schedule
    # ------------------------------------------------------------------

    async def get_schedule(self, target: Optional[date] = None) -> dict:
        """Clean week schedule. Returns days with lessons."""
        target = target or date.today()
        monday = target - __import__("datetime").timedelta(days=target.weekday())
        sunday = monday + __import__("datetime").timedelta(days=6)
        p = f"{monday.day}.{monday.month}.{monday.year}"
        f = f"{sunday.day}.{sunday.month}.{sunday.year}"
        data = await self._json(f"/schedule/index_json?p={p}&f={f}")
        return self._parse_schedule(data, monday, sunday)

    def _parse_schedule(self, data: dict, monday: date, sunday: date) -> dict:
        days: dict[int, dict] = {
            i: {"date": (monday + __import__("datetime").timedelta(days=i)).isoformat(),
                "weekday": i + 1, "lessons": []}
            for i in range(7)
        }
        for ev in data.get("Schedule") or []:
            day = int(ev.get("Day") or 0) - 1  # Day is 1-based (Mon=1)
            if day not in days:
                continue
            groups = ev.get("Groups") or []
            grp = groups[0] if groups else {}
            rooms = ev.get("Rooms") or []
            teachers = grp.get("Teachers") or []
            days[day]["lessons"].append({
                "start": ev.get("Start"),
                "end": ev.get("End"),
                "subject": grp.get("FullCaption") or grp.get("Caption") or "",
                "code": grp.get("Caption") or "",
                "color": ev.get("Color") or "#333",
                "room": ", ".join(self._d(r.get("Caption")) for r in rooms) or self._d(ev.get("Room")),
                "class": ev.get("Class") or "",
                "teachers": [t.get("LongCaption") or t.get("Caption") or "" for t in teachers],
                "group_id": grp.get("Id"),
                "info": grp.get("Info") or ev.get("Info"),
            })
        for d in days.values():
            d["lessons"].sort(key=lambda l: l.get("start") or "")
        return {"week_start": monday.isoformat(), "week_end": sunday.isoformat(), "days": list(days.values())}

    # ------------------------------------------------------------------
    # messages
    # ------------------------------------------------------------------

    _FOLDERS = {
        "inbox": "/messages/index_json",
        "sent": "/messages/index_json/outbox",
        "outbox": "/messages/index_json/outbox",
        "archive": "/messages/index_json/archive",
        "drafts": "/messages/index_json/drafts",
        "all": "/messages/index_json/all",
    }

    async def get_messages(self, folder: str = "inbox") -> list[dict]:
        path = self._FOLDERS.get(folder)
        if not path:
            raise WilmaAPIError(f"Unknown folder {folder}")
        data = await self._json(path)
        show_recipient = folder in ("sent", "outbox", "drafts")
        out = []
        for m in data.get("Messages") or []:
            who = (m.get("Recipient") if show_recipient else m.get("Sender")) or m.get("Sender") or m.get("Recipient") or ""
            out.append({
                "id": m.get("Id"),
                "subject": m.get("Subject") or "(no subject)",
                "from": who,
                "timestamp": m.get("TimeStamp"),
                "unread": bool(m.get("Status")),
                "folder": m.get("Folder") or folder,
                "replies": m.get("Replies") or 0,
            })
        return out

    async def get_message(self, mid: int) -> dict:
        r = await self._request("GET", f"/messages/{mid}", params={"format": "json"})
        data: dict = {}
        try:
            data = r.json()
        except ValueError:
            pass
        msgs = data.get("messages") or data.get("Messages") or []
        if msgs:
            m = msgs[0]
            return {
                "id": m.get("Id"),
                "subject": m.get("Subject"),
                "from": m.get("Sender"),
                "timestamp": m.get("TimeStamp"),
                "html": m.get("ContentHtml") or "",
                "bbcode": m.get("ContentBBCode") or "",
                "replies": [
                    {"from": x.get("Sender"), "timestamp": x.get("TimeStamp"), "html": x.get("ContentHtml") or ""}
                    for x in (m.get("ReplyList") or [])
                ],
                "allow_reply": m.get("AllowReply", True),
                "allow_forward": m.get("AllowForward", True),
            }
        # Fallback: HTML scrape
        return self._parse_message_html(r.text, mid)

    def _parse_message_html(self, html: str, mid: int) -> dict:
        soup = __import__("bs4").BeautifulSoup(html, "html.parser")
        title = soup.find("title")
        subject = ""
        if title and " - Wilma" in title.get_text():
            subject = title.get_text().rsplit(" - Wilma", 1)[0].strip()
        meta: dict[str, str] = {}
        for tr in soup.find_all("tr"):
            cells = tr.find_all(["th", "td"])
            if len(cells) >= 2:
                label = cells[0].get_text(" ", strip=True).rstrip(":").casefold()
                if label and label not in meta:
                    meta[label] = cells[1].get_text(" ", strip=True)
        body = soup.find("div", class_="ckeditor")
        return {
            "id": mid,
            "subject": subject,
            "from": meta.get("lähettäjä", ""),
            "timestamp": meta.get("lähetetty", ""),
            "html": str(body) if body else "",
            "replies": [],
            "allow_reply": True,
        }

    async def get_recipients(self) -> list[dict]:
        data = await self._json("/messages/recipients?format=json")
        out = []
        for r_ in data.get("Recipients") or data.get("Persons") or []:
            out.append({
                "id": r_.get("Id"),
                "name": r_.get("Caption") or r_.get("Name") or "",
                "type": r_.get("Type") or r_.get("r_type") or "",
            })
        # Some builds return HTML; fall through to panel parsing if empty
        if not out:
            r = await self._request("GET", "/messages/recipients")
            out = self._parse_recipients_html(r.text)
        return out

    def _parse_recipients_html(self, html: str) -> list[dict]:
        soup = __import__("bs4").BeautifulSoup(html, "html.parser")
        out = []
        for a in soup.find_all("a", href=True):
            href = a["href"]
            if "messages/compose" not in href:
                continue
            m = re.search(r"r_([a-z]+)=(\d+)", href)
            if m:
                out.append({"id": m.group(2), "name": a.get_text(" ", strip=True), "type": m.group(1)})
        return out

    async def reply_message(self, mid: int, body: str) -> bool:
        r = await self._request(
            "POST",
            f"/messages/collatedreply/{mid}",
            data={"bodytext": body, "formkey": self.form_key or "", "format": "json"},
        )
        return r.status_code in (200, 302) and "compose" not in str(r.url)

    async def send_message(self, recipients: list[dict], subject: str, body: str) -> bool:
        """Compose flow: GET compose with r_<type>=<id> params, then POST the form."""
        params = "&".join(f"r_{r['type']}={r['id']}" for r in recipients)
        form_r = await self._request("GET", f"/messages/compose?{params}")
        soup = __import__("bs4").BeautifulSoup(form_r.text, "html.parser")
        form = None
        for f in soup.find_all("form"):
            if f.find("textarea"):
                form = f
                break
        payload: dict[str, str] = {"formkey": self.form_key or "", "format": "json"}
        if form:
            for inp in form.find_all(["input", "textarea", "select"]):
                name = inp.get("name")
                if not name:
                    continue
                if inp.name == "textarea":
                    payload[name] = body
                elif name in ("subject", "Subject"):
                    payload[name] = subject
                elif inp.get("type") in ("hidden", "checkbox") and inp.get("value"):
                    payload[name] = inp.get("value")
        payload.setdefault("subject", subject)
        action = (form.get("action") if form else None) or "/messages/compose"
        r = await self._request("POST", action, data=payload)
        return "/compose" not in str(r.url)

    # ------------------------------------------------------------------
    # exams / news / groups / attendance
    # ------------------------------------------------------------------

    async def get_exams(self) -> list[dict]:
        data = await self._json("/exams/index_json")
        out = []
        for e in data.get("Exams") or data.get("Schedule") or []:
            out.append({
                "id": e.get("Id"),
                "course": e.get("Course") or "",
                "name": e.get("Name") or "",
                "date": e.get("Date"),
                "info": e.get("Info") or "",
                "teachers": [t.get("TeacherName") for t in (e.get("Teachers") or [])],
            })
        out.sort(key=lambda x: x.get("date") or "")
        return out

    async def get_news(self) -> list[dict]:
        data = await self._json("/news/index_json")
        return [
            {
                "id": n.get("Id"),
                "topic": n.get("Topic") or "",
                "description": n.get("Description") or "",
                "creator": n.get("Creator") or "",
                "created": n.get("Created") or "",
                "start": n.get("StartDate"),
                "end": n.get("EndDate"),
            }
            for n in (data.get("News") or [])
        ]

    async def get_groups(self) -> list[dict]:
        """Groups carry homework + exams per course."""
        data = await self._json("/groups/index_json")
        out = []
        for g in data.get("Groups") or []:
            out.append({
                "id": g.get("Id"),
                "caption": g.get("Caption") or g.get("Name") or "",
                "name": g.get("Name") or "",
                "start": g.get("StartDate"),
                "end": g.get("EndDate"),
                "teachers": [t.get("TeacherName") for t in (g.get("Teachers") or [])],
                "exams": g.get("Exams") or [],
                "homework": g.get("Homework") or [],
            })
        return out

    async def get_attendance(self, target: Optional[date] = None) -> dict:
        q = "" if target is None else f"?date={target.day}.{target.month}.{target.year}"
        data = await self._json(f"/attendance/index_json{q}")
        obs = []
        for o in data.get("Observations") or []:
            obs.append({
                "id": o.get("Id"),
                "timestamp": o.get("TimeStamp"),
                "duration": o.get("Duration"),
                "course": o.get("Course") or "",
                "teacher": o.get("TeacherName") or "",
                "type": o.get("TypeCode") or "",
                "short": o.get("TypeShort") or "",
                "name": o.get("TypeName") or "",
                "color": o.get("BackgroundColor") or "#f00",
                "requires_clearance": bool(o.get("RequiresClearance")),
            })
        return {"observations": obs, "allow_excuse": bool(data.get("AllowSaveExcuse"))}

    async def get_excuse_types(self) -> list[dict]:
        data = await self._json("/attendance?format=json")
        return [
            {"id": e.get("Id"), "caption": e.get("Caption") or "", "require_text": bool(e.get("RequireText"))}
            for e in (data.get("Excuses") or [])
        ]

    async def save_excuse(self, obs_ids: list[int], excuse_type: int, text: str = "") -> bool:
        params: dict[str, Any] = {"formkey": self.form_key or "", "format": "json", "type": excuse_type, "text": text}
        for oid in obs_ids:
            params[f"item{oid}"] = "true"
        r = await self._request("POST", "/attendance/saveexcuse", data=params)
        return r.status_code in (200, 302)

    # ------------------------------------------------------------------
    # course choices / grades (api/v1)
    # ------------------------------------------------------------------

    async def get_choices(self) -> list[dict]:
        """Course trays (course selections for lukio-era accounts)."""
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
