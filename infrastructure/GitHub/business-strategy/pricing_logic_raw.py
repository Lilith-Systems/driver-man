"""
Chokhmah (Raw Logic) Node
Autonomous Pricing Engine for Driver Man
Calculates dynamic delivery fees using multi-variate algorithmic models:
- Traffic congestion heuristics (Non-linear scaling)
- Meteorological severity indexing
- Supply-Demand equilibrium mapping
- Geodesic distance weighting
"""

import math
import time
from typing import Dict, Any

class AutonomousPricingEngine:
    def __init__(self, base_rate: float = 5.00, per_km_rate: float = 1.25):
        self.base_rate = base_rate
        self.per_km_rate = per_km_rate
        self.surge_cap = 5.0
        
    def calculate_traffic_multiplier(self, traffic_density: float) -> float:
        """
        Calculates traffic multiplier using a sigmoid function for smooth transition 
        during rush hours.
        traffic_density: 0.0 (empty) to 1.0 (gridlock)
        """
        # Sigmoid curve: steep increase around 0.7 density
        k = 10  # steepness
        x0 = 0.7 # midpoint
        multiplier = 1 + (2.0 / (1 + math.exp(-k * (traffic_density - x0))))
        return multiplier

    def calculate_weather_penalty(self, weather_data: Dict[str, Any]) -> float:
        """
        Evaluates meteorological conditions to apply hazard pay and scarcity pricing.
        """
        precipitation_mm = weather_data.get('precipitation_mm', 0.0)
        wind_speed_kmh = weather_data.get('wind_speed_kmh', 0.0)
        visibility_m = weather_data.get('visibility_m', 10000)
        
        # Non-linear weather penalty scaling
        precip_penalty = min(2.0, (precipitation_mm / 10.0) ** 1.5)
        wind_penalty = max(0, (wind_speed_kmh - 30) / 20.0)
        visibility_penalty = max(0, (5000 - visibility_m) / 2000.0)
        
        total_penalty = 1.0 + precip_penalty + wind_penalty + visibility_penalty
        return total_penalty

    def calculate_supply_demand_ratio(self, active_drivers: int, active_orders: int) -> float:
        """
        Computes the market equilibrium ratio.
        """
        if active_drivers == 0:
            return self.surge_cap
            
        ratio = active_orders / active_drivers
        # Exponential surge based on driver scarcity
        surge = math.exp(0.5 * (ratio - 1)) if ratio > 1 else 1.0
        return min(surge, self.surge_cap)

    def calculate_fee(self, distance_km: float, traffic_density: float, 
                      weather_data: Dict[str, Any], active_drivers: int, active_orders: int) -> Dict[str, float]:
        """
        Synthesizes all variables into the final autonomous pricing calculation.
        """
        # Base calculation
        distance_fee = distance_km * self.per_km_rate
        subtotal = self.base_rate + distance_fee
        
        # Multipliers
        t_mult = self.calculate_traffic_multiplier(traffic_density)
        w_mult = self.calculate_weather_penalty(weather_data)
        sd_mult = self.calculate_supply_demand_ratio(active_drivers, active_orders)
        
        # Composite dynamic multiplier (Logarithmic dampening to prevent runaway pricing)
        # Using a base reference of 3 for the log to control the growth curve
        composite_multiplier = math.log1p(t_mult * w_mult * sd_mult) / math.log1p(3)
        composite_multiplier = max(1.0, min(composite_multiplier, self.surge_cap))
        
        final_fee = subtotal * composite_multiplier
        
        return {
            'base_fee': round(self.base_rate, 2),
            'distance_fee': round(distance_fee, 2),
            'traffic_multiplier': round(t_mult, 2),
            'weather_multiplier': round(w_mult, 2),
            'supply_demand_multiplier': round(sd_mult, 2),
            'composite_multiplier': round(composite_multiplier, 2),
            'final_delivery_fee': round(final_fee, 2),
            'timestamp': time.time()
        }

if __name__ == "__main__":
    engine = AutonomousPricingEngine()
    
    # Test simulation
    weather = {'precipitation_mm': 12.5, 'wind_speed_kmh': 45.0, 'visibility_m': 2000}
    result = engine.calculate_fee(
        distance_km=8.5,
        traffic_density=0.85,
        weather_data=weather,
        active_drivers=15,
        active_orders=45
    )
    
    print("[CHOKHMAH LOGIC] Autonomous Pricing Output Generated:")
    for key, value in result.items():
        print(f"  {key}: {value}")
