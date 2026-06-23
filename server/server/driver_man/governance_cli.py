#!/usr/bin/env python3
import sys
import sqlite3
import argparse
import json
import httpx

DB_PATH = "/home/tehlappy/Desktop/Lilith/state/golem_diary.db"

def main():
    parser = argparse.ArgumentParser(description="Driver Man Governance CLI")
    parser.add_argument("--action", choices=["status", "arbitrate"], required=True)
    parser.add_argument("--id", type=str)
    
    args = parser.parse_args()
    
    if args.action == "status":
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        cur = conn.cursor()
        cur.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = [r[0] for r in cur.fetchall()]
        
        print("--- Driver Man Status ---")
        if "driver_identities" in tables:
            cur.execute("SELECT count(*) as cnt FROM driver_identities")
            print("Registered Identities:", cur.fetchone()["cnt"])
        if "dispatches" in tables:
            cur.execute("SELECT count(*) as cnt FROM dispatches")
            print("Total Dispatches:", cur.fetchone()["cnt"])
        
    elif args.action == "arbitrate":
        if not args.id:
            print("Must provide --id for arbitration")
            return
        res = httpx.post("http://localhost:3213/driver_man/arbitration", json={"driver_id": args.id, "action": "manual_arbitration"})
        print("Arbitration result:", res.status_code)

if __name__ == "__main__":
    main()
