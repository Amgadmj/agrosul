from coordinator import swarm_bus, SwarmEvent

class FaunaAgent:
    """
    Biological Cycle Prediction Agent.
    Cross-references environmental time-series data to predict pest hatching cycles.
    """
    def __init__(self):
        self.accumulated_degree_days = 0.0
        swarm_bus.subscribe("oracle.weather.log", self.calculate_biological_degree_days)

    def calculate_biological_degree_days(self, event: SwarmEvent):
        # Simplified pest biological model (e.g., Sugarcane Spittlebug)
        base_temp = 10.0
        daily_avg_temp = event.payload.get("temp_c", 0)
        
        if daily_avg_temp > base_temp:
            self.accumulated_degree_days += (daily_avg_temp - base_temp)
            
        print(f"[Agent FAUNA] Accumulated Degree Days (ADD): {self.accumulated_degree_days:.2f}")
        
        if self.accumulated_degree_days > 450.0:
            print("  🐛 [FAUNA ALERT] Predicted Spittlebug Nymph hatching threshold reached!")
            swarm_bus.publish(SwarmEvent(
                source="Fauna", 
                topic="fauna.alert.pest_emergence", 
                payload={"pest": "Spittlebug", "confidence": 0.89}
            ))
            # Reset cycle after alerting
            self.accumulated_degree_days = 0.0

fauna = FaunaAgent()
