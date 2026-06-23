import hashlib
import time

class SovereignIdentity:
    def __init__(self, driver_name: str, public_key: str):
        self.driver_name = driver_name
        self.public_key = public_key
        self.reputation_score = 100.0
        self.identity_hash = self._generate_hash()

    def _generate_hash(self) -> str:
        payload = f"{self.driver_name}:{self.public_key}:{time.time()}"
        return hashlib.sha256(payload.encode()).hexdigest()

    def update_reputation(self, delta: float):
        self.reputation_score += delta

class CooperativeNode:
    def __init__(self):
        self.registered_identities = {}

    def register_driver(self, driver: SovereignIdentity):
        self.registered_identities[driver.identity_hash] = driver
        return driver.identity_hash
