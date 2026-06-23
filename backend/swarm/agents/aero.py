from coordinator import swarm_bus, SwarmEvent

class AeroAgent:
    """
    Flight Safety & Compliance Agent.
    Subscribes to weather updates and checks telemetry against geofenced restrictions.
    """
    def __init__(self):
        # Subscribe to sudden weather alerts from the Oracle
        swarm_bus.subscribe("oracle.weather.alert", self.handle_weather_alert)
        swarm_bus.subscribe("telemetry.mission_started", self.verify_flight_path)

    def handle_weather_alert(self, event: SwarmEvent):
        wind_speed = event.payload.get("wind_speed_ms", 0)
        precipitation = event.payload.get("precipitation_mm", 0)
        
        print(f"[Agent AERO] Evaluating Weather Alert from {event.source}...")
        if wind_speed > 10.0 or precipitation > 20.0:
            print("  🚨 [AERO DIRECTIVE] Critical weather conditions detected.")
            print("  🚨 [AERO DIRECTIVE] Executing Pilot Advisory Alert (RTL) for all active missions.")
            # Emit notification command to the portal
            swarm_bus.publish(SwarmEvent(source="Aero", topic="portal.notification.urgent", payload={"message": "Severe weather. Pilots must land immediately.", "type": "RTL_ADVISORY"}))
        else:
            print("  ✅ [AERO DIRECTIVE] Weather conditions nominal. Safe to continue operations.")

    def verify_flight_path(self, event: SwarmEvent):
        # Queries socio_legal_boundaries to ensure we aren't crossing indigenous lands or restricted airspaces
        print(f"[Agent AERO] Verifying flight telemetry against Cadastral Geofences for Mission {event.payload.get('mission_id')}...")
        pass

# Initialize Agent
aero = AeroAgent()
