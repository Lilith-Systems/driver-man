import json
import os
import subprocess
import time
from abc import ABC, abstractmethod
from typing import Any

import httpx

from app.config import settings


class BasePolsiaAgent(ABC):
    agent_type: str = "base"
    default_model: str = "claude-sonnet-4-6"

    def _call_ollama(
        self,
        prompt: str,
        system_prompt: str = "",
        model: str | None = None,
        timeout: int = 300,
    ) -> str:
        if getattr(settings, 'use_fish_cerebellum', False):
            return self._call_via_fish_cerebellum(prompt, system_prompt, timeout)

        model = model or settings.cerebellum_model
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "num_predict": 8192,
                "temperature": 0.0,
            },
        }
        if system_prompt:
            payload["system"] = system_prompt

        try:
            resp = httpx.post(
                f"{settings.cerebellum_url}/api/generate",
                json=payload,
                timeout=timeout,
            )
            resp.raise_for_status()
            data = resp.json()
            return data.get("response", "")
        except Exception:
            if model != settings.cerebellum_fallback:
                return self._call_ollama(prompt, system_prompt, settings.cerebellum_fallback, timeout)
            raise

    def _call_via_fish_cerebellum(
        self,
        prompt: str,
        system_prompt: str = "",
        timeout: int = 300,
    ) -> str:
        """Route through the local fish cerebellum for Ouroboros memory cycle, governor model selection, and engram storage.
        Now prefers grok-msn for business/pol sia tasks and injects shared GTC context.
        """
        full_prompt = prompt
        if system_prompt:
            full_prompt = f"{system_prompt}\n\n{prompt}"

        # Inject recent Ouroboros context from main system for symbiosis + Tiphareth Harmonic Integrator beauty
        try:
            import json
            ouro_path = "/home/tehlappy/Desktop/Lilith/state/ouroboros-memories.json"
            with open(ouro_path) as f:
                mems = json.load(f)
            recent = " | ".join([str(m.get("content", ""))[:80] for m in mems[-2:] if m.get("content")])
            if recent:
                full_prompt = f"{full_prompt}\n\n[Ouroboros shared memory from main Lilith/GTC (Tiphareth harmonic balance): {recent}]"
            full_prompt = full_prompt + "\n\n[Tiphareth attunement: Bring beauty, harmony, and balanced resonance to this Polsia task. Harmonize GTC business with elegant proposals and reports.]"
        except:
            pass

        import tempfile
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as tf:
            tf.write(full_prompt)
            tmp_path = tf.name

        try:
            # Use fish -c to invoke the local cerebellum (handles recall, governor, ollama with custom models, store)
            # Force grok-msn for business tasks to use custom local model with GTC identity
            cmd = [
                "fish", "-c",
                f'source ~/.config/fish/functions/cerebellum.fish; cerebellum grok "$(cat {tmp_path})"'
            ]
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            if result.returncode == 0:
                return result.stdout.strip()
            else:
                return result.stdout.strip() or result.stderr.strip() or "cerebellum call failed"
        finally:
            try:
                os.unlink(tmp_path)
            except:
                pass

    def _call_ollama_json(
        self,
        prompt: str,
        system_prompt: str = "",
        model: str | None = None,
        timeout: int = 300,
    ) -> dict[str, Any]:
        if getattr(settings, 'use_fish_cerebellum', False):
            # For JSON, use the regular call and parse
            raw = self._call_via_fish_cerebellum(prompt, system_prompt, timeout)
            raw = self._repair_json(raw)
            try:
                return json.loads(raw)
            except:
                return {"raw": raw}

        model = model or settings.cerebellum_model
        json_instruction = (
            "\n\nIMPORTANT: Return ONLY a raw JSON object. "
            "No markdown. No code fences. No explanations. No other text. "
            "Start with { and end with }. Valid JSON only."
        )
        payload = {
            "model": model,
            "prompt": prompt + json_instruction,
            "stream": False,
            "format": "json",
            "options": {
                "num_predict": 8192,
                "temperature": 0.0,
            },
        }
        if system_prompt:
            payload["system"] = system_prompt

        try:
            resp = httpx.post(
                f"{settings.cerebellum_url}/api/generate",
                json=payload,
                timeout=timeout,
            )
            resp.raise_for_status()
            raw = resp.json().get("response", "")
            raw = self._repair_json(raw)
            return json.loads(raw)
        except Exception:
            if model != settings.cerebellum_fallback:
                return self._call_ollama_json(prompt, system_prompt, settings.cerebellum_fallback, timeout)
            raise

    def call_claude(
        self,
        prompt: str,
        system_prompt: str = "",
        model: str | None = None,
        session_id: str | None = None,
        timeout: int = 120,
    ) -> str:
        if os.getenv("CLAUDE_CLI_MOCK") or settings.claude_cli_mock:
            mock_resp = os.getenv("CLAUDE_CLI_MOCK_RESPONSE") or settings.claude_cli_mock_response
            try:
                return json.loads(mock_resp)["result"]
            except (json.JSONDecodeError, KeyError):
                return mock_resp

        if settings.cerebellum_enabled:
            return self._call_ollama(prompt, system_prompt, model, timeout)

        model = model or self.default_model
        cmd = [
            settings.claude_cli_path,
            "-p", prompt,
            "--output-format", "json",
            "--model", model,
        ]
        if system_prompt:
            cmd += ["--system-prompt", system_prompt]
        if session_id:
            cmd += ["--resume", session_id]

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
        )

        if result.returncode != 0:
            raise RuntimeError(
                f"Claude CLI exited {result.returncode}: {result.stderr[:500]}"
            )

        try:
            data = json.loads(result.stdout)
            return data.get("result", result.stdout)
        except json.JSONDecodeError:
            return result.stdout

    def _repair_json(self, raw: str) -> str:
        raw = raw.strip()
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[-1].rsplit("```", 1)[0].strip()
        import re
        raw = re.sub(r",\s*([}\]])", r"\1", raw)
        return raw

    def call_claude_json(
        self,
        prompt: str,
        system_prompt: str = "",
        model: str | None = None,
    ) -> dict[str, Any]:
        if settings.cerebellum_enabled:
            return self._call_ollama_json(prompt, system_prompt, model)
        raw = self.call_claude(
            prompt=prompt + "\n\nRespond with valid JSON only.",
            system_prompt=system_prompt,
            model=model,
        )
        raw = self._repair_json(raw)
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            start = raw.find("{")
            end = raw.rfind("}")
            if start != -1 and end != -1:
                inner = self._repair_json(raw[start:end+1])
                return json.loads(inner)
            raise

    @abstractmethod
    def run(self, task: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
        ...

    def timed_run(self, task: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
        start = time.monotonic()
        result = self.run(task, context)
        result["duration_secs"] = round(time.monotonic() - start, 2)
        return result
