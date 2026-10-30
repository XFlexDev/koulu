"""Session store: bearer token -> Wilma session snapshot (creds encrypted)."""

from __future__ import annotations

import json
import os
import secrets
import sqlite3
import time
from pathlib import Path

from cryptography.fernet import Fernet

DB = Path(os.environ.get("KOULU_DB", "/var/lib/koulu/koulu.db"))
KEY = os.environ.get("KOULU_SECRET", "")

if not KEY:
    KEY = Fernet.generate_key().decode()  # dev-only fallback; prod sets env
_fernet = Fernet(KEY.encode() if len(KEY) == 44 else Fernet.generate_key())


def _conn() -> sqlite3.Connection:
    DB.parent.mkdir(parents=True, exist_ok=True)
    c = sqlite3.connect(DB)
    c.execute(
        """CREATE TABLE IF NOT EXISTS sessions(
               token TEXT PRIMARY KEY,
               snapshot TEXT NOT NULL,
               created REAL,
               touched REAL
           )"""
    )
    return c


def create_session(snapshot: dict) -> str:
    token = secrets.token_urlsafe(32)
    blob = _fernet.encrypt(json.dumps(snapshot).encode()).decode()
    with _conn() as c:
        c.execute(
            "INSERT INTO sessions(token, snapshot, created, touched) VALUES(?,?,?,?)",
            (token, blob, time.time(), time.time()),
        )
    return token


def get_session(token: str) -> dict | None:
    with _conn() as c:
        row = c.execute("SELECT snapshot FROM sessions WHERE token=?", (token,)).fetchone()
        if not row:
            return None
        c.execute("UPDATE sessions SET touched=? WHERE token=?", (time.time(), token))
    try:
        return json.loads(_fernet.decrypt(row[0].encode()).decode())
    except Exception:
        return None


def update_session(token: str, snapshot: dict) -> None:
    blob = _fernet.encrypt(json.dumps(snapshot).encode()).decode()
    with _conn() as c:
        c.execute(
            "UPDATE sessions SET snapshot=?, touched=? WHERE token=?",
            (blob, time.time(), token),
        )


def delete_session(token: str) -> None:
    with _conn() as c:
        c.execute("DELETE FROM sessions WHERE token=?", (token,))
