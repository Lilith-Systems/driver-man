from __future__ import annotations

import os
import json
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Optional
from pathlib import Path

try:
    import requests
except ImportError:
    requests = None


@dataclass
class CloudResponse:
    text: str
    model: str
    provider: str
    tokens_used: int = 0
    latency_ms: float = 0.0
    cost_usd: float = 0.0
    metadata: dict = None

    def __post_init__(self):
        if self.metadata is None:
            self.metadata = {}


class CloudProvider(ABC):
    """Abstract base for cloud LLM providers"""
    
    @property
    @abstractmethod
    def name(self) -> str: ...
    
    @property
    @abstractmethod
    def models(self) -> list[str]: ...
    
    @abstractmethod
    def is_available(self) -> bool: ...
    
    @abstractmethod
    def complete(self, prompt: str, model: str, **kwargs) -> CloudResponse: ...
    
    @abstractmethod
    def stream(self, prompt: str, model: str, **kwargs): ...


class GrokProvider(CloudProvider):
    """xAI Grok API integration"""
    
    def __init__(self, api_key: str = None, base_url: str = "https://api.x.ai/v1"):
        self.api_key = api_key or os.environ.get("GROK_API_KEY")
        self.base_url = base_url.rstrip("/")
        self._models = ["grok-1", "grok-2", "grok-2-1212", "grok-3"]
    
    @property
    def name(self) -> str:
        return "grok"
    
    @property
    def models(self) -> list[str]:
        return self._models
    
    def is_available(self) -> bool:
        return bool(self.api_key and requests)
    
    def complete(self, prompt: str, model: str = "grok-2", **kwargs) -> CloudResponse:
        if not self.is_available():
            raise RuntimeError("Grok not configured: set GROK_API_KEY")
        
        start = time.time()
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": kwargs.get("temperature", 0.7),
            "max_tokens": kwargs.get("max_tokens", 4096),
            "stream": False
        }
        
        resp = requests.post(f"{self.base_url}/chat/completions", 
                           headers=headers, json=payload, timeout=60)
        resp.raise_for_status()
        data = resp.json()
        
        latency = (time.time() - start) * 1000
        choice = data["choices"][0]
        usage = data.get("usage", {})
        
        return CloudResponse(
            text=choice["message"]["content"],
            model=model,
            provider="grok",
            tokens_used=usage.get("total_tokens", 0),
            latency_ms=latency,
            metadata={"finish_reason": choice.get("finish_reason")}
        )
    
    def stream(self, prompt: str, model: str = "grok-2", **kwargs):
        if not self.is_available():
            raise RuntimeError("Grok not configured")
        
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": kwargs.get("temperature", 0.7),
            "max_tokens": kwargs.get("max_tokens", 4096),
            "stream": True
        }
        
        with requests.post(f"{self.base_url}/chat/completions",
                         headers=headers, json=payload, stream=True, timeout=60) as resp:
            resp.raise_for_status()
            for line in resp.iter_lines():
                if line:
                    line = line.decode('utf-8')
                    if line.startswith("data: "):
                        data_str = line[6:]
                        if data_str == "[DONE]":
                            break
                        try:
                            data = json.loads(data_str)
                            delta = data["choices"][0]["delta"]
                            if "content" in delta:
                                yield delta["content"]
                        except json.JSONDecodeError:
                            continue


class ReplicateProvider(CloudProvider):
    """Replicate.com API integration"""
    
    def __init__(self, api_token: str = None):
        self.api_token = api_token or os.environ.get("REPLICATE_API_TOKEN")
        self.base_url = "https://api.replicate.com/v1"
        self._models = [
            "meta/meta-llama-3-70b-instruct",
            "meta/meta-llama-3-8b-instruct",
            "mistralai/mixtral-8x7b-instruct-v0.1",
            "nvidia/nemotron-3-ultra",
            "google/gemma-2-9b-it",
            "meta/llama-3.1-405b-instruct"
        ]
    
    @property
    def name(self) -> str:
        return "replicate"
    
    @property
    def models(self) -> list[str]:
        return self._models
    
    def is_available(self) -> bool:
        return bool(self.api_token and requests)
    
    def complete(self, prompt: str, model: str = "meta/meta-llama-3-70b-instruct", **kwargs) -> CloudResponse:
        if not self.is_available():
            raise RuntimeError("Replicate not configured: set REPLICATE_API_TOKEN")
        
        start = time.time()
        headers = {
            "Authorization": f"Token {self.api_token}",
            "Content-Type": "application/json"
        }
        payload = {
            "input": {
                "prompt": prompt,
                "temperature": kwargs.get("temperature", 0.7),
                "max_tokens": kwargs.get("max_tokens", 4096),
                "system_prompt": kwargs.get("system_prompt", "")
            }
        }
        
        resp = requests.post(f"{self.base_url}/models/{model}/predictions",
                           headers=headers, json=payload, timeout=30)
        resp.raise_for_status()
        prediction = resp.json()
        
        # Poll for completion
        prediction_url = prediction["urls"]["get"]
        while prediction["status"] in ("starting", "processing"):
            time.sleep(0.5)
            poll_resp = requests.get(prediction_url, headers=headers, timeout=10)
            poll_resp.raise_for_status()
            prediction = poll_resp.json()
        
        if prediction["status"] != "succeeded":
            raise RuntimeError(f"Replicate prediction failed: {prediction.get('error')}")
        
        latency = (time.time() - start) * 1000
        output = "".join(prediction.get("output", []))
        
        return CloudResponse(
            text=output,
            model=model,
            provider="replicate",
            tokens_used=prediction.get("metrics", {}).get("total_tokens", 0),
            latency_ms=latency,
            cost_usd=prediction.get("metrics", {}).get("predict_time", 0) * 0.0001,
            metadata={"prediction_id": prediction.get("id")}
        )
    
    def stream(self, prompt: str, model: str = "meta/meta-llama-3-70b-instruct", **kwargs):
        # Replicate doesn't support native streaming, yield complete response
        result = self.complete(prompt, model, **kwargs)
        yield result.text


class CloudRouter:
    """Routes requests to cloud providers based on NGD status and model availability"""
    
    def __init__(self, config_path: str = None):
        self.config = self._load_config(config_path)
        self.providers: dict[str, CloudProvider] = {}
        self._init_providers()
    
    def _load_config(self, config_path: str) -> dict:
        default_config = {
            "providers": {
                "grok": {
                    "enabled": True,
                    "default_model": "grok-2",
                    "priority": 1
                },
                "replicate": {
                    "enabled": True,
                    "default_model": "meta/meta-llama-3-70b-instruct",
                    "priority": 2
                }
            },
            "routing": {
                "prefer_local": True,
                "fallback_order": ["grok", "replicate"],
                "cost_optimize": True
            }
        }
        
        if config_path and Path(config_path).exists():
            import yaml
            with open(config_path) as f:
                user_config = yaml.safe_load(f) or {}
            # Deep merge
            for k, v in user_config.items():
                if isinstance(v, dict) and k in default_config:
                    default_config[k].update(v)
                else:
                    default_config[k] = v
        return default_config
    
    def _init_providers(self):
        if self.config["providers"]["grok"]["enabled"]:
            try:
                self.providers["grok"] = GrokProvider()
            except Exception as e:
                print(f"Grok provider init failed: {e}")
        
        if self.config["providers"]["replicate"]["enabled"]:
            try:
                self.providers["replicate"] = ReplicateProvider()
            except Exception as e:
                print(f"Replicate provider init failed: {e}")
    
    def get_available_providers(self) -> list[str]:
        return [name for name, p in self.providers.items() if p.is_available()]
    
    def route(self, prompt: str, ngd_route: str = None, strict: bool = False, **kwargs) -> CloudResponse:
        """
        Route request based on NGD decision.
        
        Args:
            prompt: Input prompt
            ngd_route: NGD route (LOCAL_CEREBELLUM, HYBRID, CLOUD_CORTEX)
            strict: If True, respect NGD route strictly
        """
        # If NGD says LOCAL_CEREBELLUM and not forcing cloud, return local-only signal
        if ngd_route == "LOCAL_CEREBELLUM" and not kwargs.get("force_cloud", False):
            raise RuntimeError("LOCAL_CEREBELLUM: Use local inference instead")
        
        # If HYBRID and strict, only allow intent parsing locally
        if ngd_route == "HYBRID" and strict and not kwargs.get("allow_hybrid", False):
            raise RuntimeError("HYBRID (strict): Heavy inference not allowed")
        
        # Get available providers in priority order
        providers = self.get_available_providers()
        if not providers:
            raise RuntimeError("No cloud providers available")
        
        # Use priority from config
        fallback_order = self.config["routing"]["fallback_order"]
        ordered = [p for p in fallback_order if p in providers]
        ordered += [p for p in providers if p not in ordered]
        
        last_error = None
        for provider_name in ordered:
            provider = self.providers[provider_name]
            model = self.config["providers"][provider_name]["default_model"]
            model = kwargs.get("model", model)
            
            try:
                return provider.complete(prompt, model, **kwargs)
            except Exception as e:
                last_error = e
                continue
        
        raise RuntimeError(f"All cloud providers failed. Last error: {last_error}")
    
    def stream(self, prompt: str, ngd_route: str = None, strict: bool = False, **kwargs):
        """Stream from first available provider"""
        providers = self.get_available_providers()
        if not providers:
            raise RuntimeError("No cloud providers available")
        
        fallback_order = self.config["routing"]["fallback_order"]
        ordered = [p for p in fallback_order if p in providers]
        ordered += [p for p in providers if p not in ordered]
        
        for provider_name in ordered:
            provider = self.providers[provider_name]
            model = self.config["providers"][provider_name]["default_model"]
            model = kwargs.get("model", model)
            
            try:
                yield from provider.stream(prompt, model, **kwargs)
                return
            except Exception as e:
                continue
        
        raise RuntimeError("All cloud providers failed")


def create_router(config_path: str = None) -> CloudRouter:
    """Factory function"""
    return CloudRouter(config_path)
