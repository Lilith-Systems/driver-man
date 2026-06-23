#!/usr/bin/env python3
import os
import sys
import json
import httpx
import importlib.util
from pathlib import Path

# Paths
PUB_SCRIPTS = "/home/tehlappy/Desktop/AI/Pub/scripts"
LILITH_HEALTH_API = os.getenv("LILITH_HEALTH_API", "http://127.0.0.1:3213/health")
LILITH_ROUTE_API = os.getenv("LILITH_ROUTE_API", "http://127.0.0.1:3213/api/msn/route")
LILITH_API = os.getenv("LILITH_CHAT_API", "http://127.0.0.1:3213/v1/chat")
LEGACY_LILITH_API = os.getenv("LEGACY_LILITH_CHAT_API", "http://127.0.0.1:3210/v1/chat")
OLLAMA_API = "http://127.0.0.1:11434/api/chat"

# MSN skills files to verify and check
CORE_SCRIPTS = {
    "concurrent-bidirectional-memory": {
        "path": os.path.join(PUB_SCRIPTS, "bidirectional_memory_engine.py"),
        "entry_name": "BidirectionalMemoryEngine",
        "entry_type": "class"
    },
    "speculative-cerebellum": {
        "path": os.path.join(PUB_SCRIPTS, "speculative_cerebellum.py"),
        "entry_name": "execute_speculatively",
        "entry_type": "function"
    },
    "sanctuary-routing": {
        "path": os.path.join(PUB_SCRIPTS, "sanctuary_decision.py"),
        "entry_name": "run_decision_engine",
        "entry_type": "function"
    },
    "ouroboros-rnn": {
        "path": os.path.join(PUB_SCRIPTS, "ouroboros_rnn_autonomous.py"),
        "entry_name": "AutonomousRNNTrainer",
        "entry_type": "class"
    }
}

# Questions to test the LLM cognitive alignment on MSN concepts
TEST_PROMPTS = [
    {
        "skill": "sanctuary-routing",
        "question": "How does Sanctuary 2.0 mitigate VRAM thrashing on the RTX 3060? Explain the hysteresis lock.",
        "keywords": ["hysteresis", "3060", "vram", "cooldown", "90"]
    },
    {
        "skill": "speculative-cerebellum",
        "question": "What process isolation and sandboxing tools are used in the Speculative Cerebellum Phase II specification?",
        "keywords": ["sandbox", "landlock", "seccomp", "cow", "forkd"]
    },
    {
        "skill": "concurrent-bidirectional-memory",
        "question": "Explain the Doorway Effect and how the bidirectional memory engine retraces steps.",
        "keywords": ["doorway", "retrace", "forward", "backward", "golem"]
    }
]

def test_script_imports() -> dict:
    results = {}
    print("=== Testing script imports and entry point verification ===")
    for name, info in CORE_SCRIPTS.items():
        script_path = info["path"]
        entry_name = info["entry_name"]
        entry_type = info["entry_type"]
        
        if not os.path.exists(script_path):
            print(f"✗ Script not found: {script_path}")
            results[name] = {"status": "failed", "reason": "file_not_found"}
            continue
            
        try:
            # Dynamic import
            spec = importlib.util.spec_from_file_location(name, script_path)
            module = importlib.util.module_from_spec(spec)
            sys.modules[name] = module
            sys.path.insert(0, os.path.dirname(script_path))
            spec.loader.exec_module(module)
            
            # Check if entry point exists
            if hasattr(module, entry_name):
                print(f"✓ {name} successfully imported and verified {entry_type} {entry_name}.")
                results[name] = {"status": "passed", "file": script_path}
            else:
                print(f"✗ {name} imported, but {entry_type} {entry_name} not found.")
                results[name] = {"status": "failed", "reason": f"{entry_type}_{entry_name}_not_found"}
        except Exception as e:
            import traceback
            traceback.print_exc()
            print(f"✗ Error loading {name}: {e}")
            results[name] = {"status": "failed", "reason": str(e)}
            
    return results

def test_llm_resonance() -> dict:
    results = {}
    print("\n=== Testing LLM Cognitive Resonance on MSN concepts ===")
    
    # Try the current Lilith API on port 3213 first, then fall back if needed.
    client = httpx.Client(timeout=30.0)

    url = LILITH_API
    use_ollama = False
    route_status = {"ok": False, "reason": "not_checked"}
    
    try:
        r = client.get(LILITH_HEALTH_API)
        # Node server serves index.html (with text/html) on arbitrary unmatched endpoints
        if r.status_code != 200 or "text/html" in r.headers.get("content-type", ""):
            try:
                route_resp = client.post(
                    LILITH_ROUTE_API,
                    json={"prompt": TEST_PROMPTS[0]["question"]},
                )
                route_resp.raise_for_status()
                route_json = route_resp.json()
                route_status = {
                    "ok": True,
                    "focus_categories": route_json.get("focus_categories", []),
                    "focus_roles": route_json.get("focus_roles", []),
                    "selected_skills": [item.get("name") for item in route_json.get("selected_skills", [])],
                    "selected_commands": [item.get("name") for item in route_json.get("selected_commands", [])],
                }
                print("Connected to Lilith API on port 3213 and verified MSN route endpoint.")
            except Exception as exc:
                route_status = {"ok": False, "reason": str(exc)}
                print(f"Lilith route check failed: {exc}")
                if LEGACY_LILITH_API:
                    url = LEGACY_LILITH_API
                    print("Falling back to legacy Lilith backend on port 3210.")
                else:
                    url = OLLAMA_API
                    use_ollama = True
                    print("Falling back to Ollama backend direct port 11434.")
        else:
            try:
                route_resp = client.post(
                    LILITH_ROUTE_API,
                    json={"prompt": TEST_PROMPTS[0]["question"]},
                )
                route_resp.raise_for_status()
                route_json = route_resp.json()
                route_status = {
                    "ok": True,
                    "focus_categories": route_json.get("focus_categories", []),
                    "focus_roles": route_json.get("focus_roles", []),
                    "selected_skills": [item.get("name") for item in route_json.get("selected_skills", [])],
                    "selected_commands": [item.get("name") for item in route_json.get("selected_commands", [])],
                }
                print("Connected to Lilith API on port 3213 and verified MSN route endpoint.")
            except Exception as exc:
                route_status = {"ok": False, "reason": str(exc)}
                print(f"Lilith route check failed: {exc}")
    except Exception:
        try:
            r = client.get("http://127.0.0.1:3210/health")
            if r.status_code != 200 or "text/html" in r.headers.get("content-type", ""):
                raise RuntimeError("legacy Lilith API returned HTML or error")
            url = LEGACY_LILITH_API
            print("Connected to legacy Lilith API on port 3210.")
        except Exception:
            url = OLLAMA_API
            use_ollama = True
            print("Lilith API connection failed. Falling back to Ollama backend direct port 11434.")
        
    for item in TEST_PROMPTS:
        skill = item["skill"]
        question = item["question"]
        keywords = item["keywords"]
        
        print(f"Querying model for skill: {skill}...")
        
        try:
            if use_ollama:
                payload = {
                    "model": "lilith",
                    "messages": [{"role": "user", "content": question}],
                    "stream": False
                }
            else:
                payload = {
                    "messages": [{"role": "user", "content": question}]
                }
                
            resp = client.post(url, json=payload)
            resp.raise_for_status()
            
            if use_ollama:
                reply = resp.json().get("message", {}).get("content", "")
            else:
                reply = resp.json().get("reply", "")
                
            # Verify keywords in response to evaluate understanding
            matched_keywords = [kw for kw in keywords if kw.lower() in reply.lower()]
            resonance_score = len(matched_keywords) / len(keywords)
            
            passed = resonance_score >= 0.4  # Passes if at least 40% keywords match
            
            print(f"  Resonance Score: {resonance_score:.2f} ({len(matched_keywords)}/{len(keywords)} keywords matched)")
            results[skill] = {
                "status": "passed" if passed else "marginal",
                "score": resonance_score,
                "matched_keywords": matched_keywords,
                "response_preview": reply[:200].replace("\n", " ") + "...",
                "route": route_status,
            }
        except Exception as e:
            print(f"  ✗ Connection/Query failed: {e}")
            results[skill] = {"status": "failed", "reason": str(e), "route": route_status}
            
    return results

def main():
    script_results = test_script_imports()
    llm_results = test_llm_resonance()
    
    output_dir = Path("/home/tehlappy/Desktop/Lilith/reports")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    summary = {
        "status": "completed",
        "script_integration": script_results,
        "cognitive_resonance": llm_results
    }
    
    output_path = output_dir / "skills_test_report.json"
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(summary, f, indent=2)
        
    print(f"\nSkills integration test report successfully written to {output_path}")

if __name__ == "__main__":
    main()
