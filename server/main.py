"""koulu backend — FastAPI proxy over the Wilma JSON API."""

from __future__ import annotations

from datetime import datetime

from typing import Optional

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

import store
from wilma import WilmaAPIError, WilmaAuthError, WilmaClient

app = FastAPI(title="koulu")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_clients: dict[str, WilmaClient] = {}


class LoginBody(BaseModel):
    url: str
    username: str
    password: str


class ReplyBody(BaseModel):
    body: str


class ComposeBody(BaseModel):
    recipients: list[dict]  # [{"id": "12", "type": "teacher"}]
    subject: str
    body: str


class ExcuseBody(BaseModel):
    ids: list[int]
    type: int
    text: str = ""


async def client_for(request: Request) -> WilmaClient:
    auth = request.headers.get("authorization", "")
    token = auth.removeprefix("Bearer ").strip()
    if not token:
        raise HTTPException(401, "missing token")
    if token in _clients:
        return _clients[token]
    snap = store.get_session(token)
    if not snap:
        raise HTTPException(401, "unknown or expired session")
    c = WilmaClient(snap["base_url"])
    await c.restore(snap)
    c._on_relogin = lambda: store.update_session(token, c.snapshot())
    _clients[token] = c
    return c


def _token(request: Request) -> str:
    return request.headers.get("authorization", "").removeprefix("Bearer ").strip()


@app.post("/api/session")
async def login(body: LoginBody):
    c = WilmaClient(body.url)
    try:
        info = await c.login(body.username, body.password)
    except WilmaAuthError as e:
        raise HTTPException(401, str(e))
    except Exception as e:
        raise HTTPException(502, f"cannot reach Wilma: {e}")
    token = store.create_session(c.snapshot())
    _clients[token] = c
    return {"token": token, **{k: info[k] for k in ("account", "roles")}, "start_page": info.get("start_page", {})}


@app.post("/api/session/logout")
async def logout(request: Request):
    token = _token(request)
    store.delete_session(token)
    c = _clients.pop(token, None)
    if c:
        await c.close()
    return {"ok": True}


@app.get("/api/me")
async def me(c: WilmaClient = Depends(client_for)):
    return {
        "account": c.account,
        "roles": [{"name": r["name"], "type": r["type"], "slug": r["slug"]} for r in c.roles],
        "active_slug": c.slug,
    }


@app.get("/api/schedule")
async def schedule(date: Optional[str] = None, c: WilmaClient = Depends(client_for)):
    target = datetime.strptime(date, "%Y-%m-%d").date() if date else None
    try:
        return await c.get_schedule(target)
    except WilmaAPIError as e:
        raise HTTPException(502, str(e))


@app.get("/api/messages")
async def messages(folder: str = "inbox", c: WilmaClient = Depends(client_for)):
    try:
        return {"messages": await c.get_messages(folder)}
    except WilmaAPIError as e:
        raise HTTPException(502, str(e))


@app.get("/api/messages/{mid}")
async def message(mid: int, c: WilmaClient = Depends(client_for)):
    try:
        return await c.get_message(mid)
    except WilmaAPIError as e:
        raise HTTPException(502, str(e))


@app.post("/api/messages/{mid}/reply")
async def reply(mid: int, body: ReplyBody, c: WilmaClient = Depends(client_for)):
    ok = await c.reply_message(mid, body.body)
    if not ok:
        raise HTTPException(502, "reply failed")
    return {"ok": True}


@app.get("/api/recipients")
async def recipients(c: WilmaClient = Depends(client_for)):
    try:
        return {"recipients": await c.get_recipients()}
    except WilmaAPIError as e:
        raise HTTPException(502, str(e))


@app.post("/api/messages")
async def compose(body: ComposeBody, c: WilmaClient = Depends(client_for)):
    ok = await c.send_message(body.recipients, body.subject, body.body)
    if not ok:
        raise HTTPException(502, "send failed")
    return {"ok": True}


@app.get("/api/exams")
async def exams(c: WilmaClient = Depends(client_for)):
    try:
        return {"exams": await c.get_exams()}
    except WilmaAPIError as e:
        raise HTTPException(502, str(e))


@app.get("/api/news")
async def news(c: WilmaClient = Depends(client_for)):
    try:
        return {"news": await c.get_news()}
    except WilmaAPIError as e:
        raise HTTPException(502, str(e))


@app.get("/api/groups")
async def groups(c: WilmaClient = Depends(client_for)):
    try:
        return {"groups": await c.get_groups()}
    except WilmaAPIError as e:
        raise HTTPException(502, str(e))


@app.get("/api/attendance")
async def attendance(date: Optional[str] = None, c: WilmaClient = Depends(client_for)):
    target = datetime.strptime(date, "%Y-%m-%d").date() if date else None
    try:
        data = await c.get_attendance(target)
        data["excuse_types"] = await c.get_excuse_types() if data.get("allow_excuse") else []
        return data
    except WilmaAPIError as e:
        raise HTTPException(502, str(e))


@app.post("/api/attendance/excuse")
async def excuse(body: ExcuseBody, c: WilmaClient = Depends(client_for)):
    ok = await c.save_excuse(body.ids, body.type, body.text)
    if not ok:
        raise HTTPException(502, "excuse failed")
    return {"ok": True}


@app.get("/api/choices")
async def choices(c: WilmaClient = Depends(client_for)):
    return {"trays": await c.get_choices()}


@app.get("/api/health")
async def health():
    return {"ok": True}
