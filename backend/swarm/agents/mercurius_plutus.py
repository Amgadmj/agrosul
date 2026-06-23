from coordinator import swarm_bus, SwarmEvent

class MercuriusAgent:
    """
    Financial ROI & Logistics Agent.
    Weighs the cost of drone interventions against real-time market commodities.
    """
    def __init__(self):
        self.current_commodity_prices = {}
        swarm_bus.subscribe("oracle.market.price_update", self.update_market_cache)
        swarm_bus.subscribe("solis.directive.dispatch_ceres", self.calculate_intervention_roi)

    def update_market_cache(self, event: SwarmEvent):
        commodity = event.payload.get("commodity")
        price = event.payload.get("price_brl")
        self.current_commodity_prices[commodity] = price
        print(f"[Agent MERCURIUS] Updated ledger: {commodity} is now R$ {price}")

    def calculate_intervention_roi(self, event: SwarmEvent):
        # Estimate if sending a drone is worth it based on the crop value
        print("[Agent MERCURIUS] Calculating financial ROI for proposed Swarm intervention...")
        sugarcane_price = self.current_commodity_prices.get("Sugarcane", 150.0)
        
        estimated_flight_cost_brl = 450.0
        estimated_yield_save_tons = 15.0
        projected_save_value = estimated_yield_save_tons * sugarcane_price
        
        print(f"  -> Projected Yield Save Value: R$ {projected_save_value:.2f}")
        print(f"  -> Operational Flight Cost: R$ {estimated_flight_cost_brl:.2f}")
        
        if projected_save_value > estimated_flight_cost_brl:
            print("  ✅ [MERCURIUS DIRECTIVE] Intervention financially approved.")
            swarm_bus.publish(SwarmEvent(source="Mercurius", topic="mercurius.directive.approved", payload={"budget_allocated": estimated_flight_cost_brl}))
        else:
            print("  ❌ [MERCURIUS DIRECTIVE] Intervention denied. Negative ROI.")

mercurius = MercuriusAgent()
