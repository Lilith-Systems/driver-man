"""
Binah: The Structure.
Robust, type-checked, fail-safe wrapper for the Autonomous Pricing Engine.
Takes the raw, expansive logic of Chokhmah and bounds it with strict form,
ensuring stability, logging, and graceful degradation in production environments.
"""

import logging
from dataclasses import dataclass
from typing import Optional
from enum import Enum

# Configure strictly formatted logging (Binah's oversight)
logger = logging.getLogger("Binah.PricingEngine")
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s - %(name)s - [%(levelname)s] - %(message)s')
handler.setFormatter(formatter)
if not logger.handlers:
    logger.addHandler(handler)


class PricingEngineError(Exception):
    """Base exception for all pricing engine failures."""
    pass


class InvalidMarketDataError(PricingEngineError):
    """Raised when market input data violates structural constraints."""
    pass


class RiskLevel(Enum):
    LOW = "LOW"
    MODERATE = "MODERATE"
    HIGH = "HIGH"
    EXTREME = "EXTREME"


@dataclass(frozen=True)
class MarketConditions:
    """
    Strict data structure for market conditions.
    Frozen to ensure immutability during calculation.
    """
    base_price: float
    demand_multiplier: float
    inventory_level: int
    competitor_price: Optional[float] = None
    volatility_index: float = 1.0

    def validate(self) -> None:
        """Enforces Binah's strict boundaries on Chokhmah's inputs."""
        if not isinstance(self.base_price, (int, float)) or self.base_price <= 0.0:
            raise InvalidMarketDataError("Base price must be a positive number.")
        if not isinstance(self.demand_multiplier, (int, float)) or self.demand_multiplier < 0.0:
            raise InvalidMarketDataError("Demand multiplier cannot be negative.")
        if not isinstance(self.inventory_level, int) or self.inventory_level < 0:
            raise InvalidMarketDataError("Inventory level must be a non-negative integer.")
        if self.competitor_price is not None and (not isinstance(self.competitor_price, (int, float)) or self.competitor_price <= 0.0):
            raise InvalidMarketDataError("Competitor price, if provided, must be positive.")
        if not isinstance(self.volatility_index, (int, float)) or self.volatility_index < 0.0:
            raise InvalidMarketDataError("Volatility index cannot be negative.")


class AutonomousPricingEngine:
    """
    The wrapper that contains Chokhmah's raw pricing algorithm within Binah's structure.
    Guarantees a valid return price, falling back to safe limits upon failure.
    """

    def __init__(self, min_margin: float = 0.10, max_margin: float = 0.80):
        self._min_margin = float(min_margin)
        self._max_margin = float(max_margin)

    def _chokhmah_raw_calculation(self, conditions: MarketConditions) -> float:
        """
        The raw, expansive logic. Calculates the theoretical optimal price.
        Unbounded and potentially chaotic, it relies on Binah to reign it in.
        """
        # Base expansion
        target = float(conditions.base_price * conditions.demand_multiplier)

        # Scarcity premium (exponential response to low inventory)
        if conditions.inventory_level < 10:
            target *= (1.0 + (10 - conditions.inventory_level) * 0.05)

        # Volatility fluctuation
        target *= float(conditions.volatility_index)

        # Competitor anchoring
        if conditions.competitor_price:
            # Undercut competitor slightly if demand is normal, else ignore
            if conditions.demand_multiplier <= 1.2:
                target = min(target, conditions.competitor_price * 0.98)

        return target

    def calculate_optimal_price(self, conditions: MarketConditions) -> float:
        """
        The production-safe entry point. Imposes form, catches chaos, and ensures survival.
        """
        try:
            # 1. Strict Input Validation
            conditions.validate()
            
            # 2. Raw Calculation
            raw_price = self._chokhmah_raw_calculation(conditions)
            
            # 3. Impose Boundaries (Binah's restriction)
            min_allowed_price = conditions.base_price * (1.0 + self._min_margin)
            max_allowed_price = conditions.base_price * (1.0 + self._max_margin)
            
            final_price = max(min_allowed_price, min(raw_price, max_allowed_price))
            
            logger.info(
                f"Calculation successful: Base={conditions.base_price:.2f}, "
                f"Raw={raw_price:.2f}, Final={final_price:.2f}"
            )
            return round(final_price, 2)
            
        except InvalidMarketDataError as e:
            logger.error(f"Validation failed: {e}. Falling back to safe minimum margin.")
            return self._fallback_price(getattr(conditions, 'base_price', 1.0))
            
        except Exception as e:
            logger.critical(f"Catastrophic failure in raw logic: {e}. Executing emergency fallback.")
            # In a true fail-safe system, we never crash. We return a survival value.
            return self._fallback_price(getattr(conditions, 'base_price', 1.0))

    def _fallback_price(self, base_price: float) -> float:
        """
        The final safety net. When all else fails, structure remains.
        """
        try:
            safe_price = float(base_price) * (1.0 + self._min_margin)
            return round(max(safe_price, 0.01), 2)  # Ensure non-zero positive
        except Exception:
            return 1.0  # Absolute fallback if base_price is irreparably corrupted


if __name__ == "__main__":
    # Test suite to prove the structure's resilience
    engine = AutonomousPricingEngine()
    
    print("--- Binah Protocol: Pricing Engine Verification ---")
    
    # 1. Normal Conditions
    normal_cond = MarketConditions(base_price=100.0, demand_multiplier=1.1, inventory_level=50, competitor_price=120.0)
    print(f"Normal Output: ${engine.calculate_optimal_price(normal_cond):.2f}")
    
    # 2. Extreme Demand (Bounded by max margin)
    extreme_cond = MarketConditions(base_price=100.0, demand_multiplier=3.0, inventory_level=5)
    print(f"Extreme Output (Bounded): ${engine.calculate_optimal_price(extreme_cond):.2f}")
    
    # 3. Invalid Data (Graceful Degradation)
    try:
        invalid_cond = MarketConditions(base_price=-50.0, demand_multiplier=1.0, inventory_level=10)
        print(f"Invalid Output: ${engine.calculate_optimal_price(invalid_cond):.2f}")
    except Exception as e:
        print(f"Failed to even construct (dataclass check): {e}")

    # 4. Corrupt Data Type fallback
    try:
        # Intentionally passing bad types ignoring type hints
        corrupt_cond = MarketConditions(base_price="One Hundred", demand_multiplier=1.0, inventory_level=10)
        print(f"Corrupt Type Output: ${engine.calculate_optimal_price(corrupt_cond):.2f}")
    except Exception as e:
        print(f"Fallback Execution Result: ${engine.calculate_optimal_price(corrupt_cond):.2f}")
