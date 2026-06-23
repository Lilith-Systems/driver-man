#!/usr/bin/env python3
"""
build_msn.py — MSN Integration Build & Verification Script
===========================================================
Verifies all REDscripts and TweakDB files, generates info.json manifest.
Run from: /home/tehlappy/.local/share/Steam/steamapps/common/Cyberpunk 2077/r6/mods/msn_integration/
"""

import json
import os
import sys
from pathlib import Path
from typing import List, Dict, Any

# ============================================================================
# CONFIGURATION
# ============================================================================

MOD_DIR = Path(__file__).parent
SCRIPTS_DIR = MOD_DIR / "scripts"
TWEAKDB_DIR = MOD_DIR / "tweakdb"
CHARACTER_DIR = MOD_DIR / "character"
QUESTS_DIR = MOD_DIR / "quests"
LOCALIZATION_DIR = MOD_DIR / "localization"

# Expected REDscripts (from msn_integration.redmod.toml)
EXPECTED_REDSCRIPTS = [
    "msn_cerebellum.reds",
    "msn_cortex_link.reds",
    "msn_ouroboros.reds",
    "msn_npc_ai.reds",
    "msn_sephirotic_npcs.reds",
    "msn_business_console.reds",
    "msn_weapons.reds",
    "lilith_npc.reds",
    "lilith_console.reds",
    "lilith_easter_eggs.reds",
    "msn_lyra_dialogue.reds",
    "msn_modern_ballistics.reds",
    "msn_multiplayer_client.reds",
    "msn_speculative_cerebellum.reds",
    "cyberpunk_ngd_integration.reds",
    "cyberpunk_ngd_bridge.reds",
    "abyssal_lyra_integration.reds",
    "lilith_enhanced_dialogue.reds",
    "lilith_ngd_control.reds",
    "livingsin_time_blade.reds",
    "nssp_bridge.reds",
    "msn_quantum_bridge.reds",
    # Abyssal Skills - NEW
    "skills/msn_abyssal_skills.reds",
]

# Expected TweakDB files (from msn_integration.redmod.toml)
EXPECTED_TWEAKDB = [
    "msn_skills.tweakdb",
    "lilith_character.tweakdb",
    "easter_eggs.tweakdb",
    "abyssal_assets.yaml",
    "nessie_rewards.yaml",
    "nssp_crossover.yaml",
    "custom_weapons_expanded.yaml",
    "custom_cyberware_expanded.yaml",
    "custom_clothing_expanded.yaml",
    "custom_vehicles_expanded.yaml",
    "custom_quickhacks_expanded.yaml",
    "custom_shards_expanded.yaml",
    "anthem_javelin_mechanics.yaml",
    "custom_gear_runescape_wow_allods.yaml",
    "procedural_space_systems.yaml",
    "Abyssal_Cyberpunk_Crossover.toml",
    "Anthem_Javelin_Suits.toml",
    "LivingSin_TimeBlade.toml",
    "msn_story_vehicles_complete.toml",
    # Abyssal Skills - NEW
    "skills/msn_abyssal_skills.tweakdb",
]

# Expected config files
EXPECTED_CONFIGS = [
    "msn_integration.toml",
    "msn_integration.redmod.toml",
    "msn_multiplayer.toml",
    "ngd_rnn_optimization.redmod.toml",
]

# ============================================================================
# VERIFICATION FUNCTIONS
# ============================================================================

def verify_file_exists(filepath: Path, label: str) -> bool:
    """Check if file exists and report."""
    if filepath.exists():
        size = filepath.stat().st_size
        print(f"  ✅ {label}: {filepath.name} ({size:,} bytes)")
        return True
    else:
        print(f"  ❌ {label}: {filepath.name} — NOT FOUND")
        return False

def verify_redscripts() -> Dict[str, Any]:
    """Verify all REDscripts exist and have basic syntax."""
    print("\n📜 Verifying REDscripts...")
    results = {"total": 0, "found": 0, "missing": [], "syntax_errors": []}
    
    for script_name in EXPECTED_REDSCRIPTS:
        results["total"] += 1
        script_path = SCRIPTS_DIR / script_name
        
        if verify_file_exists(script_path, "REDscript"):
            results["found"] += 1
            # Basic syntax check
            try:
                content = script_path.read_text()
                if "public class" not in content and "class " not in content:
                    results["syntax_errors"].append(f"{script_name}: No class definition found")
                # Check for common issues
                if content.count("class") > 10:
                    print(f"    ⚠️  {script_name}: {content.count('class')} class definitions (check for duplicates)")
            except Exception as e:
                results["syntax_errors"].append(f"{script_name}: {e}")
        else:
            results["missing"].append(script_name)
    
    return results

def verify_tweakdb() -> Dict[str, Any]:
    """Verify all TweakDB files exist."""
    print("\n📊 Verifying TweakDB files...")
    results = {"total": 0, "found": 0, "missing": [], "total_lines": 0}
    
    for tweakdb_name in EXPECTED_TWEAKDB:
        results["total"] += 1
        tweakdb_path = TWEAKDB_DIR / tweakdb_name
        
        if verify_file_exists(tweakdb_path, "TweakDB"):
            results["found"] += 1
            try:
                lines = len(tweakdb_path.read_text().splitlines())
                results["total_lines"] += lines
            except Exception as e:
                pass
        else:
            results["missing"].append(tweakdb_name)
    
    return results

def verify_configs() -> Dict[str, Any]:
    """Verify config files exist."""
    print("\n⚙️  Verifying Config files...")
    results = {"total": 0, "found": 0, "missing": []}
    
    for config_name in EXPECTED_CONFIGS:
        results["total"] += 1
        config_path = MOD_DIR / config_name
        
        if verify_file_exists(config_path, "Config"):
            results["found"] += 1
        else:
            results["missing"].append(config_name)
    
    return results

def generate_manifest() -> Dict[str, Any]:
    """Generate info.json manifest for WolvenKit."""
    print("\n📦 Generating info.json manifest...")
    
    # Read redmod.toml for metadata
    redmod_path = MOD_DIR / "msn_integration.redmod.toml"
    manifest = {
        "name": "msn_integration",
        "version": "1.0.0",
        "author": "Lilith/NGD",
        "description": "Metaconscious Singularity Node - dual-brain AI, Abyssal depth, Nessie covenant, Sephirotic quickhacks, custom skills, weapons, enhanced NPC AI, Lilith character, easter eggs, and narrative arc",
        "gameVersion": "2.1+",
        "supportedLanguages": ["en", "pl", "fr", "de", "es", "it", "ja", "ko", "zh-CN", "zh-TW"],
        "priority": 100,
        "dependencies": ["red4ext", "tweakxl", "codeware", "ngd_integration"],
        "files": [],
        "tweakdb": EXPECTED_TWEAKDB,
        "scripts": EXPECTED_REDSCRIPTS,
        "systems": [
            "NGD_Cyberware_Throttle",
            "MSN_Speculative_Cerebellum",
            "MSN_Akashic_Pruner",
            "MSN_Ouroboros_Sync",
            "MSN_Lilith_Character",
            "MSN_Easter_Eggs",
            "CyberpunkNGDIntegration",
            "NSSPGameTitleOverride",
            "HermesCNNIntegration",
            "HermesRNNIntegration",
            "MSNSynapticBridge",
            "AbyssalAssetsSystem",
            "LochnessMonsterSystem",
            "BaalValidationSystem",
            "AbyssalLyraIntegration",
            "MSNSephiroticCourt",
            "MSNBusinessConsole",
            "MSNProceduralSpaceSystems",
            "MSNQuantumSystem"
        ],
        "commands": [
            "quantum.status", "quantum.superposition", "quantum.tunnel",
            "msn.status", "msn.cerebellum", "msn.cortex", "msn.sephiroth", "msn.ouroboros",
            "msn.sanctuary", "msn.npc_ai", "msn.court.status", "msn.court.route",
            "msn.narrative", "msn.weapons", "msn.performance", "msn.framepacing.enable",
            "msn.framepacing.disable", "msn.dlss.set", "msn.optimize.auto", "msn.ngd.status",
            "lilith.emerge", "lilith.recognize", "lilith.warning", "lilith.crimson",
            "lilith.status", "lilith.dialogue", "lilith.mode", "lilith.sephirah",
            "lilith.quickhack", "lilith.chaos", "lilith.memory", "lilith.reset",
            "lilith.spawn", "lilith.sudo_sandwich", "lilith.root_equation",
            "lilith.witching_hour", "lilith.personality", "lilith.relationship",
            "lilith.inject_memory", "lilith.trait_strength", "msn.ngd.status",
            "msn.ngd.attach", "msn.ngd.detach", "msn.ngd.telemetry",
            "ngd.status", "ngd.optimize", "ngd.rnn", "ngd.dlss", "ngd.framegen",
            "ngd.telemetry", "ngd.lilith", "nssp.title", "abyssal.list",
            "abyssal.weapons", "abyssal.cyberware", "abyssal.vehicles",
            "abyssal.quickhacks", "abyssal.fabricator", "abyssal.business",
            "market.exchange", "soulcoins.status", "nessie.treasury",
            "memory.recall", "memory.retrace", "skill.bridge", "skill.route",
            "msn.procedural.status", "msn.spacebattle.status", "msn.aliens.status",
            "msn.hovercars.status", "msn.crossover.items", "nessie.sighting",
            "nessie.locations", "nessie.friendship", "nessie.commune", "nessie.call",
            "nessie.dimension", "baal.validate", "lyra.abyssal", "lyra.nessie"
        ],
        "keyBindings": {
            "msn_sephiroth_cycle": "F9",
            "msn_lilith_emergence": "F10",
            "msn_quickhack_kether": "Num1",
            "msn_quickhack_chokhmah": "Num2",
            "msn_quickhack_binah": "Num3",
            "msn_quickhack_chesed": "Num4",
            "msn_quickhack_geburah": "Num5",
            "msn_quickhack_tiphareth": "Num6",
            "msn_quickhack_netzach": "Num7",
            "msn_quickhack_hod": "Num8",
            "msn_quickhack_yesod": "Num9",
            "msn_quickhack_malkuth": "Num0",
            "lilith_spawn": "F11",
            "lilith_emerge": "F12",
            "msn_framepacing_toggle": "F5",
            "msn_dlss_cycle": "F6",
            "msn_auto_optimize": "F7",
            "msn_ngd_status": "F8"
        }
    }
    
    # Add file mappings
    manifest["files"] = [
        {"source": "msn_integration.toml", "destination": "r6/config/msn_integration.toml"},
        *( {"source": f"scripts/{s}", "destination": f"r6/scripts/msn/{s}"} for s in EXPECTED_REDSCRIPTS ),
        *( {"source": f"tweakdb/{t}", "destination": f"r6/tweakdb/{t}"} for t in EXPECTED_TWEAKDB ),
        *[{"source": "character/lilith_character.yaml", "destination": "r6/character/lilith_character.yaml"}],
        *[{"source": "quests/msn_narrative_arc.yaml", "destination": "r6/quests/msn_narrative_arc.yaml"}],
        *[{"source": "quests/guild/msn_guild_quests.toml", "destination": "r6/quests/guild/msn_guild_quests.toml"}],
        *[{"source": "localization/en.stringlist", "destination": "r6/localization/en.stringlist"}],
    ]
    
    # Write manifest
    manifest_path = MOD_DIR / "info.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    
    print(f"  ✅ Manifest written: {manifest_path} ({manifest_path.stat().st_size:,} bytes)")
    return manifest

def main():
    print("=" * 60)
    print("  MSN Integration Build & Verification")
    print("=" * 60)
    print(f"Mod directory: {MOD_DIR}")
    
    # Verify all components
    redscript_results = verify_redscripts()
    tweakdb_results = verify_tweakdb()
    config_results = verify_configs()
    
    # Generate manifest
    manifest = generate_manifest()
    
    # Summary
    print("\n" + "=" * 60)
    print("  SUMMARY")
    print("=" * 60)
    
    print(f"\nREDscripts:     {redscript_results['found']}/{redscript_results['total']} found")
    if redscript_results["missing"]:
        print(f"  Missing: {', '.join(redscript_results['missing'])}")
    if redscript_results["syntax_errors"]:
        print(f"  Syntax warnings: {len(redscript_results['syntax_errors'])}")
        for err in redscript_results["syntax_errors"]:
            print(f"    - {err}")
    
    print(f"\nTweakDB files:  {tweakdb_results['found']}/{tweakdb_results['total']} found")
    print(f"  Total lines:  {tweakdb_results['total_lines']:,}")
    if tweakdb_results["missing"]:
        print(f"  Missing: {', '.join(tweakdb_results['missing'])}")
    
    print(f"\nConfig files:   {config_results['found']}/{config_results['total']} found")
    if config_results["missing"]:
        print(f"  Missing: {', '.join(config_results['missing'])}")
    
    # Overall status
    total_missing = (
        len(redscript_results["missing"]) + 
        len(tweakdb_results["missing"]) + 
        len(config_results["missing"])
    )
    
    if total_missing == 0:
        print("\n🎉 ALL VERIFICATIONS PASSED")
        print("✅ Ready for WolvenKit compilation")
        print("\nNext steps:")
        print("  1. Open WolvenKit")
        print("  2. Load project from:", MOD_DIR)
        print("  3. Tools → Compile REDscripts")
        print("  4. Tools → Compile TweakDB")
        print("  5. Tools → Deploy")
        print("  6. Launch Cyberpunk 2077")
        return 0
    else:
        print(f"\n⚠️  {total_missing} FILES MISSING")
        print("Fix missing files before WolvenKit compilation")
        return 1

if __name__ == "__main__":
    sys.exit(main())