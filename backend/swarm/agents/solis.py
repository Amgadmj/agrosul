from coordinator import swarm_bus, SwarmEvent

class SolisAgent:
    """
    Satellite / Macro Monitoring Agent.
    Analyzes wide-scale spectral indices (NDVI) from Sentinel-2/Landsat to detect sudden drops in biomass.
    """
    def __init__(self):
        swarm_bus.subscribe("oracle.satellite.ndvi_update", self.analyze_vegetation_index)

    def analyze_vegetation_index(self, event: SwarmEvent):
        print(f"[Agent SOLIS] Analyzing macro-spectral indices for Plot {event.payload.get('farm_plot_id')}")
        ndvi_delta = event.payload.get("ndvi_delta_percent", 0)
        
        if ndvi_delta < -15.0:
            print(f"  ⚠️ [SOLIS ALERT] Sudden {ndvi_delta}% drop in biomass detected!")
            # Request a human pilot scouting mission via the portal
            target_poly = event.payload.get("anomaly_polygon")
            directive_payload = {
                "message": "NDVI drop detected. Recommend pilot scouting mission.",
                "target_polygon": target_poly,
                "priority": "HIGH"
            }
            swarm_bus.publish(SwarmEvent(source="Solis", topic="portal.mission.create", payload=directive_payload))

solis = SolisAgent()
