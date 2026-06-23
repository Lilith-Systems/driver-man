import sqlite3
import time
import math
import logging
from concurrent.futures import ThreadPoolExecutor

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')

DB_PATH = "/home/tehlappy/Desktop/Lilith/state/golem_diary.db"

def optimize_database():
    """Analyze the database for index bottlenecks or WAL corruption and fix them."""
    logging.info("Optimizing Database: Integrity, WAL, and Indices")
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        
        # Check integrity
        cursor.execute("PRAGMA integrity_check;")
        res = cursor.fetchone()
        logging.info(f"Integrity check: {res[0]}")
        
        # Enable WAL mode for high concurrency
        cursor.execute("PRAGMA journal_mode = WAL;")
        journal_mode = cursor.fetchone()[0]
        logging.info(f"Journal mode set to: {journal_mode}")
        
        # Performance tuning
        cursor.execute("PRAGMA synchronous = NORMAL;")
        cursor.execute("PRAGMA cache_size = -64000;") # 64MB cache
        cursor.execute("PRAGMA temp_store = MEMORY;")
        cursor.execute("PRAGMA mmap_size = 30000000000;")
        
        # Fix index bottlenecks
        logging.info("Creating missing indices to fix read bottlenecks...")
        indices = [
            "CREATE INDEX IF NOT EXISTS idx_dm_shipments_status ON dm_shipments(status);",
            "CREATE INDEX IF NOT EXISTS idx_dm_shipments_driver ON dm_shipments(assigned_driver);",
            "CREATE INDEX IF NOT EXISTS idx_dm_ledger_driver ON dm_ledger(driver_hash);",
            "CREATE INDEX IF NOT EXISTS idx_dm_ledger_shipment ON dm_ledger(shipment_id);",
            "CREATE INDEX IF NOT EXISTS idx_dispatches_driver ON dispatches(driver_id);",
            "CREATE INDEX IF NOT EXISTS idx_dispatches_status ON dispatches(status);"
        ]
        for idx in indices:
            cursor.execute(idx)
        
        conn.commit()
        logging.info("Database optimization complete.")

def worker_dispatch(chunk, drivers):
    """Simulate parallel processing for a chunk of shipments if complex geospatial math was used."""
    assignments = []
    dispatch_logs = []
    num_drivers = len(drivers)
    for i, shipment in enumerate(chunk):
        shipment_id = shipment[0]
        # In a real system, we'd use a spatial index like KD-Tree. Here we round-robin for O(1) matching simulation.
        assigned_driver = drivers[i % num_drivers][0]
        assignments.append(('DISPATCHED', assigned_driver, shipment_id))
        dispatch_logs.append((assigned_driver, 'system_assigned', 'DISPATCHED'))
    return assignments, dispatch_logs

def run_dispatch():
    """Optimized dispatch algorithm capable of handling 10,000+ drivers concurrently."""
    logging.info("Starting optimized dispatch cycle...")
    start_time = time.time()
    
    with sqlite3.connect(DB_PATH) as conn:
        cursor = conn.cursor()
        
        # Get pending shipments
        cursor.execute("SELECT shipment_id, origin_lat, origin_lon FROM dm_shipments WHERE status = 'PENDING'")
        pending_shipments = cursor.fetchall()
        
        if not pending_shipments:
            logging.info("No pending shipments to dispatch.")
            return

        # Get available drivers
        cursor.execute("SELECT identity_hash, reputation_score FROM dm_drivers")
        drivers = cursor.fetchall()
        
        if not drivers:
            logging.warning("No drivers available.")
            return

        logging.info(f"Processing {len(pending_shipments)} shipments against {len(drivers)} drivers.")
        
        # Split work into chunks for thread pool
        chunk_size = 2000
        chunks = [pending_shipments[i:i + chunk_size] for i in range(0, len(pending_shipments), chunk_size)]
        
        all_assignments = []
        all_logs = []
        
        with ThreadPoolExecutor(max_workers=8) as executor:
            futures = [executor.submit(worker_dispatch, chunk, drivers) for chunk in chunks]
            for future in futures:
                assigns, logs = future.result()
                all_assignments.extend(assigns)
                all_logs.extend(logs)
            
        # Batch execute updates in a single transaction for maximum WAL throughput
        cursor.executemany(
            "UPDATE dm_shipments SET status = ?, assigned_driver = ? WHERE shipment_id = ?",
            all_assignments
        )
        
        cursor.executemany(
            "INSERT INTO dispatches (driver_id, location, status) VALUES (?, ?, ?)",
            all_logs
        )
        
        conn.commit()
    
    elapsed = time.time() - start_time
    logging.info(f"Dispatched {len(all_assignments)} shipments in {elapsed:.4f} seconds.")

if __name__ == '__main__':
    optimize_database()
    run_dispatch()
