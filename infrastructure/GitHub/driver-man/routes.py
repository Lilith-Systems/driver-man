from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Request, HTTPException, Depends
from typing import Dict, Any, List
import sqlite3
import json
import asyncio
from pydantic import BaseModel

router = APIRouter(prefix="/driver_man", tags=["Driver Man"])

def get_db():
    conn = sqlite3.connect("/home/tehlappy/Desktop/Lilith/state/golem_diary.db")
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()

connected_clients: List[WebSocket] = []

class IdentityReg(BaseModel):
    driver_id: str
    vehicle_type: str

class DispatchReq(BaseModel):
    driver_id: str
    location: str

@router.post("/identity/register")
async def register_identity(reg: IdentityReg, db: sqlite3.Connection = Depends(get_db)):
    db.execute('''CREATE TABLE IF NOT EXISTS driver_identities
                  (driver_id TEXT PRIMARY KEY, vehicle_type TEXT)''')
    try:
        db.execute("INSERT INTO driver_identities (driver_id, vehicle_type) VALUES (?, ?)", 
                   (reg.driver_id, reg.vehicle_type))
        db.commit()
    except sqlite3.IntegrityError:
        # Ignore for simulation simplicity
        pass
    return {"status": "success", "driver_id": reg.driver_id}

@router.post("/dispatch")
async def dispatch_driver(req: DispatchReq, db: sqlite3.Connection = Depends(get_db)):
    db.execute('''CREATE TABLE IF NOT EXISTS dispatches
                  (id INTEGER PRIMARY KEY AUTOINCREMENT, driver_id TEXT, location TEXT, status TEXT)''')
    db.execute("INSERT INTO dispatches (driver_id, location, status) VALUES (?, ?, ?)", 
               (req.driver_id, req.location, "DISPATCHED"))
    db.commit()
    
    dead_clients = []
    for client in connected_clients:
        try:
            await client.send_json({"event": "dispatch", "driver_id": req.driver_id, "location": req.location})
        except:
            dead_clients.append(client)
    for c in dead_clients:
        connected_clients.remove(c)

    return {"status": "dispatched", "driver_id": req.driver_id}

@router.websocket("/telemetry")
async def websocket_telemetry(websocket: WebSocket):
    await websocket.accept()
    connected_clients.append(websocket)
    try:
        while True:
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        if websocket in connected_clients:
            connected_clients.remove(websocket)

@router.post("/ledger/webhook")
async def ledger_webhook(payload: dict, db: sqlite3.Connection = Depends(get_db)):
    db.execute('''CREATE TABLE IF NOT EXISTS ledgers
                  (id INTEGER PRIMARY KEY AUTOINCREMENT, payload TEXT)''')
    db.execute("INSERT INTO ledgers (payload) VALUES (?)", (json.dumps(payload),))
    db.commit()
    return {"status": "recorded"}

@router.post("/arbitration")
async def arbitration(req: Request, db: sqlite3.Connection = Depends(get_db)):
    payload = await req.json()
    db.execute('''CREATE TABLE IF NOT EXISTS arbitrations
                  (id INTEGER PRIMARY KEY AUTOINCREMENT, detail TEXT)''')
    db.execute("INSERT INTO arbitrations (detail) VALUES (?)", (json.dumps(payload),))
    db.commit()
    return {"status": "arbitrated"}
