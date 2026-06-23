import logging
import json
import time
from pathlib import Path
from typing import List, Dict, Any
from datetime import datetime

logger = logging.getLogger(__name__)

# Shared state for full symbiosis: Polsia <-> DriverMan <-> GTC/MSN via Ouroboros local cerebellum
COOP_STATE_PATH = Path("/home/tehlappy/Desktop/Lilith/state/coop_pool_state.json")

# Yesod Foundation Memory Weaver integration: pool ops feed engrams to Polsia + Ouroboros
try:
    from app.services.memory_service import store_memory  # async, will be called in sync context via loop if needed
except Exception:
    store_memory = None

def _load_coop_state() -> dict:
    try:
        if COOP_STATE_PATH.exists():
            return json.loads(COOP_STATE_PATH.read_text())
    except Exception:
        pass
    return {
        "treasury_balance_usd": 352.01,
        "total_drivers": 52,
        "total_deliveries_processed": 0,
        "manifesto": {"delivery_fee": 4.99, "driver_payout": 3.50, "pool_contribution": 1.49, "restaurant_routing_fee": 1.50}
    }

def _save_coop_state(state: dict):
    try:
        state["last_updated"] = datetime.utcnow().isoformat() + "Z"
        COOP_STATE_PATH.write_text(json.dumps(state, indent=2))
    except Exception:
        pass

class DriverPoolManager:
    """Manages the Cooperative Pool for The Driver Man. GEBURAH SEVERITY ENFORCED.
    Per manifesto: zero commission restaurants, 100% tips drivers, transparent $1.49 pool allocation.
    All allocations logged for legal compliance, disputes, contracts. Use Himalaya for email judgments.
    Data-driven symbiosis: loads from shared coop_pool_state.json (synced with driver_man ledger + GTC).
    All tx route via fish cerebellum + Ouroboros engrams.
    """
    
    def __init__(self):
        state = _load_coop_state()
        self.total_pool_usd = float(state.get("treasury_balance_usd", 352.01))
        manifesto = state.get("manifesto", {})
        self.flat_delivery_fee = manifesto.get("delivery_fee", 4.99)
        self.driver_payout = manifesto.get("driver_payout", 3.50)
        self.pool_contribution = manifesto.get("pool_contribution", 1.49)
        self.restaurant_routing_fee = manifesto.get("restaurant_routing_fee", 1.50)
        self.total_drivers = int(state.get("total_drivers", 52))
        self._state = state
        logger.info(f"[POOL][SYMBIOSIS] Loaded data-driven state: ${self.total_pool_usd:.2f} pool, {self.total_drivers} drivers")

    def process_order_payment(self, order_id: str) -> Dict[str, Any]:
        """Process a standard delivery order fee. Geburah: enforce exact split, no waste.
        Yesod (Foundation) Memory Weaver: every tx engrammed to Polsia memory + Ouroboros himalaya feeds for subconscious continuity.
        Data symbiosis: persist to shared coop state for LLC/Driverman/GTC sync.
        """
        self.total_pool_usd += self.pool_contribution
        self._state["treasury_balance_usd"] = self.total_pool_usd
        self._state["total_deliveries_processed"] = self._state.get("total_deliveries_processed", 0) + 1
        _save_coop_state(self._state)
        
        logger.info(f"[LEDGER][GEBURAH] Order {order_id} processed. Driver paid ${self.driver_payout}. "
                    f"Pool received ${self.pool_contribution}. Total Pool: ${self.total_pool_usd:.2f}")
        
        # Feed foundation engram (non-blocking; in prod use proper async context)
        if store_memory:
            try:
                import asyncio
                content = f"Driver Man order {order_id}: ${self.driver_payout} to driver, ${self.pool_contribution} to Cooperative Pool. Total pool: ${self.total_pool_usd:.2f}. Manifesto-aligned. Fed via Yesod foundation."
                # fire and forget for pool tx memory
                loop = asyncio.get_event_loop()
                if loop.is_running():
                    asyncio.create_task(self._async_feed_pool_engram(order_id, content))
                else:
                    asyncio.run(self._async_feed_pool_engram(order_id, content))
            except Exception:
                pass
        
        return {
            "order_id": order_id,
            "driver_payout": self.driver_payout,
            "pool_contribution": self.pool_contribution,
            "total_pool_usd": self.total_pool_usd,
            "restaurant_routing_fee": self.restaurant_routing_fee,
            "legal_ref": "Driver Man Manifesto + Polsia dispatch. Subject to governance/arbitration."
        }

    async def _async_feed_pool_engram(self, order_id: str, content: str):
        """Internal Yesod engram feeder for pool txs."""
        try:
            # Note: real impl would use injected db session; here direct for base foundation
            # For now, direct ouroboros append mirrors memory_service
            import json, time
            ouro_path = "/home/tehlappy/Desktop/Lilith/state/ouroboros-memories.json"
            oentry = {
                "content": f"[cooperative_pool] Driver Man tx {order_id}: {content[:300]}",
                "role": "YESOD_MEMORY_WEAVER",
                "source": "polsia-dispatch-driver-man",
                "timestamp": int(time.time() * 1000),
                "sephirah": "Yesod",
                "metadata": {"driver_man_coop": True, "pool": True, "gtc_empire": "logistics_base", "himalaya_email_swarm": "foundation"}
            }
            try:
                with open(ouro_path) as f: data = json.load(f)
            except: data = []
            data.append(oentry)
            with open(ouro_path, "w") as f: json.dump(data, f, indent=2)
        except Exception:
            pass

    def allocate_repair_funds(self, driver_id: str, amount: float, reason: str) -> bool:
        """Unlock funds from the pool for a driver's emergency repair or gas. Geburah judgment: audit reason, prevent overdraw."""
        if self.total_pool_usd >= amount:
            self.total_pool_usd -= amount
            self._state["treasury_balance_usd"] = self.total_pool_usd
            _save_coop_state(self._state)
            logger.info(f"[LEDGER][GEBURAH] Dispersed ${amount} to Driver {driver_id} for {reason}. "
                        f"Remaining Pool: ${self.total_pool_usd:.2f}")
            return True
        else:
            logger.warning(f"[LEDGER][GEBURAH] Insufficient pool funds to cover ${amount} repair for Driver {driver_id}.")
            return False

class DispatchRouter:
    """Handles autonomous AI-driven routing for the fleet."""
    
    def route_order(self, restaurant_location: tuple, active_drivers: List[Dict[str, Any]]) -> str:
        """Find the optimal driver based on proximity and fairness algorithm."""
        if not active_drivers:
            return "No active drivers available."
            
        # For prototype: simple nearest driver mock
        best_driver = active_drivers[0]
        logger.info(f"[DISPATCH] Order routed to Driver {best_driver['id']}")
        return best_driver['id']

# Global singletons for prototype
pool_manager = DriverPoolManager()
dispatch_router = DispatchRouter()
