import uuid
import datetime
from pydantic import BaseModel, Field
from typing import List, Any, Dict, Callable
from webhook_client import dispatch_portal_webhook

class SwarmEvent(BaseModel):
    event_id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    source: str
    topic: str
    payload: Dict[str, Any]
    timestamp: datetime.datetime = Field(default_factory=datetime.datetime.now)

class SwarmCoordinator:
    """
    Deterministic Pub/Sub Event Bus for the Agrosul Swarm.
    Ensures safe, auditable routing of data from the Oracle to specialized Agents.
    """
    def __init__(self):
        self.subscribers: Dict[str, List[Callable]] = {}
        self.event_log: List[SwarmEvent] = []

    def subscribe(self, topic: str, callback: Callable):
        if topic not in self.subscribers:
            self.subscribers[topic] = []
        self.subscribers[topic].append(callback)
        print(f"[SwarmCoordinator] Agent subscribed to {topic}")

    def publish(self, event: SwarmEvent):
        print(f"\n[Swarm Event Bus] Routing '{event.topic}' from {event.source}...")
        self.event_log.append(event)
        
        # Intercept portal notifications and fire webhook to Next.js
        if event.topic.startswith("portal."):
            dispatch_portal_webhook(event)
        
        if event.topic in self.subscribers:
            for callback in self.subscribers[event.topic]:
                try:
                    callback(event)
                except Exception as e:
                    print(f"[Swarm Error] Failed to process event in subscriber: {e}")
        else:
            print(f"[Swarm Event Bus] No active agents subscribed to '{event.topic}'.")

# Global singleton for the orchestration bus
swarm_bus = SwarmCoordinator()
