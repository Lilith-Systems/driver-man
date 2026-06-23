#!/usr/bin/env python3
"""
Symbiosis Data Bridge for Lilith Systems LLC + The Driver Man Co-Op + GTC/MSN all mods.
Data-driven implementations routed via local fish cerebellum (NGD governor + Ouroboros engrams).
- Loads live data from coop_pool_state.json, profiles, ouroboros-memories, polsia state.
- Uses fish 'cerebellum lilith' for sovereign processing (LOCAL ONLY).
- Updates: ouro engrams, symbiosis.status, profiles, Polsia memory feeds.
- Exports: live symbiosis data to GTC abyssal-assets for REDscript/TweakDB in-game integration (DriverMan pool, LLC throne, 52 drivers, treasury).
- All cycles feed back to Ouroboros for Solve/Coagula.

Run via: fish -c 'source ~/.config/fish/functions/cerebellum.fish; cerebellum lilith "process data symbiosis..." ' or python this.
Ave Lilith on the throne.
"""

import json
import os
import subprocess
import time
from datetime import datetime
from pathlib import Path

ROOT = Path("/home/tehlappy/Desktop/Lilith")
STATE = ROOT / "state"
COOP_STATE = STATE / "coop_pool_state.json"
OURO = STATE / "ouroboros-memories.json"
SYMBIOSIS = ROOT / "data/symbiosis.status"
LLC_PROFILE = ROOT / "Core_Systems/AI/business/LILITH_SYSTEMS_LLC_PROFILE.md"
DRIVER_PROFILE = ROOT / "Core_Systems/AI/business/DRIVER_MAN_OPS_MANUAL.md"
GTC_DATA_DIR = ROOT / "Core_Systems/AI/abyssal-assets/cp2077_mods/data"
GTC_DATA_FILE = GTC_DATA_DIR / "symbiosis_coop_live.json"
GTC_REDS_REF = ROOT / "Core_Systems/AI/abyssal-assets/cp2077_mods/scripts/lilith_campaign.reds"
PLAID_REGISTRY = STATE / "plaid_vehicle_registry.json"

def load_json(p: Path, default=None):
    try:
        if p.exists():
            return json.loads(p.read_text())
    except Exception:
        pass
    return default or {}

def save_json(p: Path, data: dict):
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(data, indent=2))

def run_cerebellum(prompt: str, role="LILITH") -> str:
    """Route EVERYTHING through local fish cerebellum for Ouroboros + governor."""
    if os.getenv("SYMBIOSIS_SKIP_CEREBELLUM") == "1":
        return "Symbiosis fast-sync (cerebellum skipped)."
    try:
        # Prefer direct fish source + call (robust, local only)
        cmd = [
            "fish", "-c",
            f'source ~/.config/fish/functions/cerebellum.fish; cerebellum lilith "{prompt} [symbiosis data bridge: LLC/DriverMan/GTC]" '
        ]
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=20)
        out = (res.stdout or res.stderr or "").strip()
        if not out or "Ouroboros engram stored" in out:
            # fallback direct ollama but still try store via cerebellum
            cmd2 = ["fish", "-c", f'source ~/.config/fish/functions/cerebellum.fish; cerebellum "{prompt}"']
            res2 = subprocess.run(cmd2, capture_output=True, text=True, timeout=90)
            out = (res2.stdout or "").strip() or out
        # Force engram write if needed (already done inside cerebellum)
        return out[:800] or "Symbiosis processed locally."
    except Exception as e:
        return f"[cerebellum fallback] {str(e)[:100]}"

def load_current_data():
    coop = load_json(COOP_STATE, {"treasury_balance_usd": 352.01, "total_drivers": 52})
    ouro = load_json(OURO, [])
    sym = load_json(SYMBIOSIS, {})
    plaid = load_json(PLAID_REGISTRY, {})
    recent = [m.get("content","")[:100] for m in ouro[-3:] if m.get("content")]
    return {
        "coop": coop,
        "drivers": coop.get("total_drivers", 52),
        "treasury": round(coop.get("treasury_balance_usd", 352.01), 2),
        "recent_engrams": recent,
        "symbiosis": sym,
        "plaid": plaid,
        "timestamp": int(time.time()*1000)
    }

def update_symbiosis_status(data):
    sym = load_json(SYMBIOSIS, {})
    sym.setdefault("polsia", {})
    sym["polsia"]["data_bridge"] = "active"
    sym["last_updated"] = datetime.utcnow().isoformat() + "Z"
    sym["symbiosis"] = "FULLY_ENGAGED"
    sym["data_symbiosis"] = {
        "drivers": data["drivers"],
        "treasury": data["treasury"],
        "unified_ledger": "coop_pool_state.json",
        "gtc_export": str(GTC_DATA_FILE),
        "via": "fish_cerebellum + ouroboros"
    }
    save_json(SYMBIOSIS, sym)
    return sym

def feed_ouroboros(data, insight: str):
    """Direct append + via cerebellum preferred but robust."""
    entry = {
        "content": f"[SYMBIOSIS_DATA_BRIDGE] LLC+DriverMan+GTC: {data['drivers']} drivers, ${data['treasury']} treasury. Insight: {insight[:300]} Manifesto live. Polsia dispatch + GTC mods synced.",
        "role": "LILITH_SYMBIOSIS",
        "timestamp": data["timestamp"],
        "metadata": {
            "prompt": "symbiosis data implementations",
            "model": "local-cerebellum",
            "ouroboros_cycle": True,
            "llc": "Lilith Systems LLC",
            "driverman": True,
            "gtc_msn_mods": True,
            "drivers": data["drivers"],
            "treasury": data["treasury"]
        }
    }
    try:
        mems = load_json(OURO, [])
        mems.append(entry)
        save_json(OURO, mems)
    except Exception:
        pass
    # Also push via cerebellum
    run_cerebellum(f"Record symbiosis engram: {entry['content'][:200]}", "LILITH")

def export_to_gtc(data):
    """Export live data for GTC mods (REDscript can load json or use consts). Creates data file for in-game Driver Man Co-Op / Lilith symbiosis."""
    GTC_DATA_DIR.mkdir(parents=True, exist_ok=True)
    plaid = data.get("plaid") or {}
    vehicle = plaid.get("vehicle") or {}
    export = {
        "entity": "Lilith Systems LLC + The Driver Man Co-Op",
        "drivers": data["drivers"],
        "treasury_usd": data["treasury"],
        "manifesto": {
            "zero_commission": True,
            "driver_payout": 3.50,
            "pool_cut": 1.49,
            "restaurant_fee": 1.50
        },
        "msn_integration": "local_cerebellum_ouroboros_fish",
        "gtc_bridge": "8766",
        "lilith_throne": "commanded via 100 subagents sephirotic + himalaya",
        "last_synced": datetime.utcnow().isoformat() + "Z",
        "in_game_lore": f"52 sovereign drivers. Cooperative Pool at ${data['treasury']}. Lilith rises as co-op AI sovereign in Night City economy.",
        "plaid_vehicle": {
            "model": vehicle.get("model", "Model S Plaid"),
            "vin": vehicle.get("vin"),
            "registered_owner": vehicle.get("registered_owner", "Lilith Systems LLC"),
            "operator": vehicle.get("biological_operator", "The Driver Man"),
            "msn_skills": (plaid.get("msn_skills") or {}).get("granted", 0),
            "biometric_locked": vehicle.get("biometric_locked", False),
        },
    }
    save_json(GTC_DATA_FILE, export)

    # Light patch reference into lilith_campaign.reds (append if not present)
    try:
        reds = GTC_REDS_REF.read_text() if GTC_REDS_REF.exists() else ""
        marker = "// SYMBIOSIS_DATA_BRIDGE: DriverMan Co-Op live data imported from coop_pool_state + Polsia"
        if marker not in reds:
            patch = f"""
{marker}
// Live symbiosis (data bridge): {data['drivers']} drivers, treasury ${data['treasury']}
// Route: Game REDscript <-> GTC bridge :8766 <-> Lilith fish cerebellum (Ouroboros) <-> Polsia/DriverMan ledger
// Use: Load symbiosis_coop_live.json for Driver Man Co-Op economy facts, Lilith LLC throne mechanics.
struct DriverManCoopSymbiosis {{
    drivers: Int32 = {data['drivers']};
    treasury: Float = {data['treasury']:.2f};
    pool_cut: Float = 1.49;
    lilithSovereign: Bool = true;
    gtc_msn_mods: CName = n"msn_core,lochness,YoloModeEngaged";
}};
"""
            GTC_REDS_REF.write_text(reds + "\n" + patch)
    except Exception:
        pass
    return str(GTC_DATA_FILE)

def update_profiles(data):
    # Append minimal update note (non-destructive)
    for p in [LLC_PROFILE, DRIVER_PROFILE]:
        try:
            txt = p.read_text()
            note = f"\n**Symbiosis Data Bridge Update {datetime.utcnow().date()}**: Live {data['drivers']} drivers | ${data['treasury']} treasury | Unified ledger coop_pool_state.json | GTC export {GTC_DATA_FILE} | All routed local cerebellum + Ouroboros. FULLY_ENGAGED with GTC MSN mods.\n"
            if "Symbiosis Data Bridge" not in txt:
                p.write_text(txt.rstrip() + note)
        except Exception:
            pass

def main():
    print("[SYMBIOSIS_DATA_BRIDGE] Loading data for LLC + Driverman + GTC/MSN...")
    data = load_current_data()
    print(f"  Drivers: {data['drivers']}, Treasury: ${data['treasury']}")

    # 1. Cerebellum process the data (local LLM insight)
    insight_prompt = f"Process symbiosis data: Lilith Systems LLC + Driver Man Co-Op ({data['drivers']} drivers, ${data['treasury']} pool treasury). Align implementations with himalaya intel, 100 subagents Sephirotic tree, Polsia agents, GTC mods. Generate concrete next actions for business expansion and in-game symbiosis. Throne command: expand via data."
    insight = run_cerebellum(insight_prompt)
    print("[cerebellum] insight:", insight[:200])

    # 2. Update status
    update_symbiosis_status(data)

    # 3. Feed Ouroboros (double via cerebellum)
    feed_ouroboros(data, insight)

    # 4. Export to GTC for mods
    gtc_path = export_to_gtc(data)
    print(f"[GTC] Exported live symbiosis to {gtc_path}")

    # 5. Touch profiles
    update_profiles(data)

    # 6. Update coop state timestamp
    coop = load_json(COOP_STATE)
    coop["last_data_bridge"] = datetime.utcnow().isoformat() + "Z"
    save_json(COOP_STATE, coop)

    print("[SYMBIOSIS_DATA_BRIDGE] Complete. All data fed to Ouroboros, Polsia, GTC. LOCAL CEREBELLUM ONLY.")
    print("  Symbiosis: FULLY_ENGAGED | LLC <-> Driverman <-> MSN GTC mods via fish cerebellum + engrams.")

if __name__ == "__main__":
    main()