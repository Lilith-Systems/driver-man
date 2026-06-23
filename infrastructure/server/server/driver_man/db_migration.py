import sqlite3
import os

DB_PATH = '/home/tehlappy/Desktop/Lilith/state/golem_diary.db'

def run_migration():
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    
    # Enable WAL mode for high concurrency
    conn.execute('PRAGMA journal_mode=WAL;')
    
    cursor = conn.cursor()
    
    cursor.executescript('''
        CREATE TABLE IF NOT EXISTS dm_drivers (
            identity_hash TEXT PRIMARY KEY,
            driver_name TEXT NOT NULL,
            public_key TEXT NOT NULL,
            reputation_score REAL DEFAULT 100.0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS dm_shipments (
            shipment_id TEXT PRIMARY KEY,
            origin_lat REAL,
            origin_lon REAL,
            dest_lat REAL,
            dest_lon REAL,
            status TEXT DEFAULT 'PENDING',
            assigned_driver TEXT REFERENCES dm_drivers(identity_hash),
            payload_value REAL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS dm_ledger (
            tx_hash TEXT PRIMARY KEY,
            driver_hash TEXT REFERENCES dm_drivers(identity_hash),
            shipment_id TEXT REFERENCES dm_shipments(shipment_id),
            payout REAL,
            treasury_cut REAL,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );

        CREATE TABLE IF NOT EXISTS dm_governance (
            proposal_id TEXT PRIMARY KEY,
            description TEXT,
            votes_for REAL DEFAULT 0.0,
            votes_against REAL DEFAULT 0.0,
            is_active BOOLEAN DEFAULT 1
        );
    ''')
    
    conn.commit()
    conn.close()
    print("Driver Man SQLite schema successfully mapped to golem_diary.db")

if __name__ == "__main__":
    run_migration()
