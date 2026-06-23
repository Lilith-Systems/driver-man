#!/usr/bin/env python3
"""
Lilith Desktop NGD + Cloud Integration
Checks NGD status, routes to local or cloud (Grok/Replicate) based on routing decision
"""
import json
import time
import sys
from pathlib import Path
from typing import Optional

# Add src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from ngd.cloud_providers import CloudRouter, create_router


class NGDCloudIntegration:
    def __init__(self, 
                 status_path: str = None,
                 cloud_config: str = None):
        self.status_path = Path(status_path or "~/invite/runtime/nvidia_gratitude_driver/status.json").expanduser()
        self.cloud_config = Path(cloud_config or "~/.config/ngd/cloud_providers.yaml").expanduser()
        self.router = create_router(str(self.cloud_config) if self.cloud_config.exists() else None)
        self.lucifer_url = "http://localhost:8766"
        
    def get_ngd_status(self) -> dict:
        """Read NGD status.json"""
        if not self.status_path.exists():
            return {"error": "NGD status file not found", "route": "UNKNOWN"}
        try:
            return json.loads(self.status_path.read_text())
        except Exception as e:
            return {"error": str(e), "route": "UNKNOWN"}
    
    def get_lucifer_health(self) -> dict:
        """Query Lucifer HTTP monitoring plane"""
        try:
            import requests
            resp = requests.get(f"{self.lucifer_url}/health", timeout=2)
            return resp.json()
        except Exception:
            return {"error": "Lucifer unavailable"}
    
    def get_routing_decision(self) -> dict:
        """Full routing decision for Lilith orchestration"""
        ngd = self.get_ngd_status()
        lucifer = self.get_lucifer_health()
        
        route = ngd.get("route", "UNKNOWN")
        cooldown = ngd.get("cooldown_active", False)
        
        # Determine local inference permission
        if route == "LOCAL_CEREBELLUM":
            local_allowed = True
            reason = "NGD: LOCAL_CEREBELLUM - local inference allowed"
        elif route == "HYBRID":
            local_allowed = True
            reason = "NGD: HYBRID - local intent parsing only (cloud for heavy)"
        elif route == "CLOUD_CORTEX":
            if cooldown:
                remaining = ngd.get("human", {}).get("cooldown_seconds_remaining", 0)
                local_allowed = False
                reason = f"NGD: CLOUD_CORTEX cooldown active ({remaining:.0f}s remaining)"
            else:
                local_allowed = True
                reason = "NGD: CLOUD_CORTEX (no cooldown) - cloud recommended"
        else:
            local_allowed = False
            reason = f"NGD: UNKNOWN route ({route})"
        
        return {
            "ngd": ngd,
            "lucifer": lucifer,
            "local_inference_allowed": local_allowed,
            "reason": reason,
            "cloud_providers_available": self.router.get_available_providers(),
            "timestamp": time.time()
        }
    
    def complete(self, prompt: str, **kwargs) -> dict:
        """
        Complete a prompt using NGD-guided routing.
        Returns dict with response and routing info.
        """
        decision = self.get_routing_decision()
        
        # Try local first if allowed
        if decision["local_inference_allowed"] and not kwargs.get("force_cloud", False):
            return {
                "route": "local",
                "decision": decision,
                "response": None,  # Caller handles local inference
                "message": "Local inference allowed by NGD"
            }
        
        # Route to cloud
        ngd_route = decision["ngd"].get("route", "UNKNOWN")
        strict = kwargs.get("strict", False)
        
        try:
            cloud_resp = self.router.route(prompt, ngd_route=ngd_route, strict=strict, **kwargs)
            return {
                "route": "cloud",
                "provider": cloud_resp.provider,
                "model": cloud_resp.model,
                "decision": decision,
                "response": {
                    "text": cloud_resp.text,
                    "tokens_used": cloud_resp.tokens_used,
                    "latency_ms": cloud_resp.latency_ms,
                    "cost_usd": cloud_resp.cost_usd
                },
                "message": f"Cloud completion via {cloud_resp.provider}"
            }
        except Exception as e:
            return {
                "route": "error",
                "decision": decision,
                "error": str(e),
                "message": "All cloud providers failed"
            }
    
    def stream(self, prompt: str, **kwargs):
        """Stream completion"""
        decision = self.get_routing_decision()
        ngd_route = decision["ngd"].get("route", "UNKNOWN")
        strict = kwargs.get("strict", False)
        
        if decision["local_inference_allowed"] and not kwargs.get("force_cloud", False):
            yield {"type": "local_allowed", "decision": decision}
            return
        
        try:
            for chunk in self.router.stream(prompt, ngd_route=ngd_route, strict=strict, **kwargs):
                yield {"type": "chunk", "text": chunk}
            yield {"type": "done", "decision": decision}
        except Exception as e:
            yield {"type": "error", "error": str(e), "decision": decision}


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Lilith NGD+Cloud Integration")
    parser.add_argument("prompt", nargs="?", help="Prompt to complete")
    parser.add_argument("--force-cloud", action="store_true", help="Force cloud even if local allowed")
    parser.add_argument("--strict", action="store_true", help="Strict NGD routing")
    parser.add_argument("--stream", action="store_true", help="Stream response")
    parser.add_argument("--status-only", action="store_true", help="Just show routing decision")
    args = parser.parse_args()
    
    integration = NGDCloudIntegration()
    
    if args.status_only:
        decision = integration.get_routing_decision()
        print(json.dumps(decision, indent=2))
        sys.exit(0 if decision["local_inference_allowed"] else 1)
    
    if not args.prompt:
        parser.print_help()
        sys.exit(1)
    
    if args.stream:
        for chunk in integration.stream(args.prompt, force_cloud=args.force_cloud, strict=args.strict):
            print(json.dumps(chunk))
    else:
        result = integration.complete(args.prompt, force_cloud=args.force_cloud, strict=args.strict)
        print(json.dumps(result, indent=2))
