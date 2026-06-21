from dataclasses import dataclass, field
from typing import List, Optional
import uuid
from enum import Enum

class LogisticsError(Exception):
    """Base exception for the Logistics Engine."""
    pass

class CapacityExceededError(LogisticsError):
    """Raised when a vehicle's capacity is exceeded."""
    pass

class InvalidLocationError(LogisticsError):
    """Raised when location coordinates are invalid."""
    pass

class Status(Enum):
    PENDING = "PENDING"
    IN_TRANSIT = "IN_TRANSIT"
    DELIVERED = "DELIVERED"
    FAILED = "FAILED"

@dataclass
class Location:
    lat: float
    lon: float
    name: str

    def __post_init__(self) -> None:
        if not (-90.0 <= self.lat <= 90.0):
            raise InvalidLocationError(f"Latitude must be between -90 and 90, got {self.lat}")
        if not (-180.0 <= self.lon <= 180.0):
            raise InvalidLocationError(f"Longitude must be between -180 and 180, got {self.lon}")

@dataclass
class Item:
    item_id: str
    weight_kg: float
    volume_m3: float

    def __post_init__(self) -> None:
        if self.weight_kg <= 0 or self.volume_m3 <= 0:
            raise ValueError("Item weight and volume must be strictly positive.")

@dataclass
class Shipment:
    shipment_id: str
    origin: Location
    destination: Location
    items: List[Item] = field(default_factory=list)
    status: Status = Status.PENDING

    @property
    def total_weight(self) -> float:
        return sum(item.weight_kg for item in self.items)

    @property
    def total_volume(self) -> float:
        return sum(item.volume_m3 for item in self.items)

    def add_item(self, item: Item) -> None:
        self.items.append(item)

@dataclass
class Vehicle:
    vehicle_id: str
    max_weight_kg: float
    max_volume_m3: float
    current_location: Location
    shipments: List[Shipment] = field(default_factory=list)

    def can_carry(self, shipment: Shipment) -> bool:
        current_weight = sum(s.total_weight for s in self.shipments)
        current_volume = sum(s.total_volume for s in self.shipments)
        
        return (current_weight + shipment.total_weight <= self.max_weight_kg and 
                current_volume + shipment.total_volume <= self.max_volume_m3)

    def load_shipment(self, shipment: Shipment) -> None:
        if not self.can_carry(shipment):
            raise CapacityExceededError(
                f"Vehicle {self.vehicle_id} cannot carry shipment {shipment.shipment_id} due to capacity constraints."
            )
        self.shipments.append(shipment)
        shipment.status = Status.IN_TRANSIT
