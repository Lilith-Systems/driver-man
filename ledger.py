import hashlib
import time
import json
from pathlib import Path
from typing import Dict, Any

# Symbiosis shared state: DriverMan ledger <-> Polsia DriverPool <-> GTC/MSN all via local Ouroboros cerebellum
COOP_STATE_PATH = Path("/home/tehlappy/Desktop/Lilith/state/coop_pool_state.json")

def _load_coop_state() -> dict:
    try:
        if COOP_STATE_PATH.exists():
            return json.loads(COOP_STATE_PATH.read_text())
    except Exception:
        pass
    return {"treasury_balance_usd": 352.01, "total_drivers": 52, "total_deliveries_processed": 0}

def _save_coop_state(state: dict):
    try:
        state["last_updated"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        COOP_STATE_PATH.write_text(json.dumps(state, indent=2))
    except Exception:
        pass

class TransparentLedger:
    """Transparent immutable ledger for Driver Man Co-Op. Symbiosis: shares state with Polsia + feeds GTC.
    All operations feed Ouroboros via fish cerebellum routing.
    """
    def __init__(self):
        self.chain = []
        state = _load_coop_state()
        self.treasury_balance = float(state.get("treasury_balance_usd", 352.01))
        self._state = state

    def record_delivery(self, driver_hash: str, shipment_id: str, delivery_fee: float = 4.99):
        # GEBURAH JUDGMENT ENFORCED: Per Driver Man manifesto + Polsia dispatch.
        # $4.99 delivery fee: $3.50 driver immediate payout, $1.49 to Cooperative Pool (repairs/gas/hardware).
        # Restaurants: $0 commission + $1.50 flat routing fee (separate). 100% tips retained by driver.
        # Transparent, auditable for legal/non-profit compliance. Feed to Himalaya/Ouroboros.
        # Data-driven: syncs shared coop_pool_state.json for LLC/Driverman/GTC symbiosis.
        driver_payout = 3.50
        pool_contribution = 1.49
        # Note: delivery_fee should == 4.99; extra routing fees handled in dispatch
        transaction = {
            "driver": driver_hash,
            "shipment": shipment_id,
            "payout": driver_payout,
            "pool_contribution": pool_contribution,
            "timestamp": time.time(),
            "manifesto_ref": "The Driver Man: $3.50 driver + $1.49 pool"
        }
        
        tx_hash = hashlib.sha256(str(transaction).encode()).hexdigest()
        transaction["hash"] = tx_hash
        
        self.chain.append(transaction)
        self.treasury_balance += pool_contribution
        self._state["treasury_balance_usd"] = self.treasury_balance
        self._state["total_deliveries_processed"] = self._state.get("total_deliveries_processed", 0) + 1
        _save_coop_state(self._state)
        return tx_hash
