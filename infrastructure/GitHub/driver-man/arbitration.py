import random
from typing import List

class PeerArbitration:
    def __init__(self, high_reputation_drivers: List[str]):
        # Represents driver hashes with reputation > 95.0
        self.eligible_arbitrators = high_reputation_drivers
        self.active_disputes = {}

    def raise_dispute(self, dispute_id: str, shipper_id: str, driver_hash: str, claim: str):
        # Peer Arbitration: disputes are routed to a rotating panel of highly-rated peers
        panel = random.sample(self.eligible_arbitrators, min(3, len(self.eligible_arbitrators)))
        
        self.active_disputes[dispute_id] = {
            "shipper": shipper_id,
            "driver": driver_hash,
            "claim": claim,
            "panel": panel,
            "status": "AWAITING_REVIEW"
        }
        return panel

    def resolve_dispute(self, dispute_id: str, ruling: str):
        if dispute_id in self.active_disputes:
            self.active_disputes[dispute_id]["status"] = "RESOLVED"
            self.active_disputes[dispute_id]["ruling"] = ruling
