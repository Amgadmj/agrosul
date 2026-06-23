import requests
import json
from pydantic import BaseModel

NEXTJS_PORTAL_URL = "http://localhost:3000/api/notifications"

def dispatch_portal_webhook(event):
    """
    Intercepts any SwarmEvent destined for the Next.js Pilot Portal and fires an HTTP POST webhook.
    """
    if not event.topic.startswith("portal."):
        return

    print(f"[WebhookClient] Dispatching {event.topic} alert to Pilot Dashboard...")
    
    # In production, we'd extract the correct producer_id from the context.
    # For prototyping, we use a mock UUID.
    mock_producer_id = "00000000-0000-0000-0000-000000000001"
    
    # We must serialize the datetime object
    event_dict = event.model_dump()
    event_dict["timestamp"] = event_dict["timestamp"].isoformat()
    
    payload = {
        "producer_id": mock_producer_id,
        "agent_source": event.source,
        "topic": event.topic,
        "message": event.payload.get("message", "No message provided."),
        "raw_payload": event_dict
    }

    try:
        response = requests.post(
            NEXTJS_PORTAL_URL, 
            json=payload,
            headers={"Content-Type": "application/json"}
        )
        if response.status_code == 200:
            print("  -> ✅ Webhook successfully delivered to Next.js API")
        else:
            print(f"  -> ⚠️ Webhook delivery failed: HTTP {response.status_code}")
    except requests.exceptions.RequestException as e:
        print(f"  -> ❌ Next.js portal is unreachable: {e}")
