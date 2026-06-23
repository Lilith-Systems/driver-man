#!/usr/bin/env python3
"""Validate the MSN magic/Jedi REDmod surface.

This is intentionally conservative and local-only. It does not launch
Cyberpunk or write to the Steam install; it checks the workspace mod bundle
for the wiring needed before a REDmod/WolvenKit deployment attempt.
"""

from __future__ import annotations

import json
import re
import sys
import tomllib
import hashlib
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

SCRIPT_REFS = {
    "magic/msn_magic_system.reds",
    "jedi/msn_jedi_system.reds",
    "starwars/msn_starwars_system.reds",
}
TWEAKDB_REFS = {"tweakdb/msn_magic_jedi.tweakdb"}
IGNORED_LEGACY_TWEAKDB_HASHES = {
    "tweakdb/msn_magic.tweakdb": "ea8181163dffe1608a8ba8aa6fc4f09397f8ea2f537644b70d29b72f3c5f6a21",
    "tweakdb/msn_magic_part2.tweakdb": "d5091126fec208ecf514f86874b508d07c484f2d8507f913d05ea02bbca75777",
    "tweakdb/msn_magic_part3.tweakdb": "9822ba6bbd4404d0d6b05402b2acf837d12792dbf7f93fa469f27785e892abf2",
    "tweakdb/msn_magic_part4.tweakdb": "905a270c0fee3d69e7170f8bcdb9bbf83257d5998a816965734d40cda14695e6",
}
COMMANDS = {
    "msn.magic.status",
    "msn.magic.cast",
    "msn.magic.attune",
    "msn.jedi.status",
    "msn.jedi.power",
    "msn.jedi.align",
    "msn.starwars.status",
}
MAGIC_SPELLS = [
    "MagicMissile",
    "Fireball",
    "LightningBolt",
    "MageArmor",
    "Shield",
    "DetectMagic",
    "Teleport",
    "SummonFamiliar",
    "Heal",
    "RaiseDead",
    "TimeStop",
    "Wish",
]
JEDI_POWERS = [
    "ForcePush",
    "ForcePull",
    "ForceLeap",
    "ForceSense",
    "ForceStasis",
    "ForceChoke",
    "ForceHeal",
    "SaberFormShiiCho",
    "SaberFormMakashi",
    "SaberFormDjemSo",
]
LOCALIZATION_KEYS = {
    "msn_magic_status",
    "msn_magic_cast",
    "msn_magic_attune",
    "msn_jedi_status",
    "msn_jedi_power",
    "msn_jedi_align",
    "msn_starwars_status",
    "msn_arcane_cerebellum_name",
    "msn_arcane_cerebellum_desc",
    "msn_arcane_focus_name",
    "msn_arcane_focus_desc",
    "msn_staff_power_name",
    "msn_staff_power_desc",
    "msn_wand_fireball_name",
    "msn_wand_fireball_desc",
    "msn_force_implant_name",
    "msn_force_implant_desc",
    "msn_plasma_saber_name",
    "msn_plasma_saber_desc",
}
DATA_RECORD_PREFIX = re.compile(
    r"^(Item|Ability|Vehicle|Shard|SkillTree|Perk|Quickhack|Cyberware):",
    re.MULTILINE,
)


def fail(message: str) -> None:
    print(f"FAIL: {message}")
    raise SystemExit(1)


def read(path: str) -> str:
    return (ROOT / path).read_text()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def check_balanced(path: Path) -> None:
    text = path.read_text()
    if text.count("{") != text.count("}"):
        fail(f"{path.relative_to(ROOT)} has unbalanced braces")
    if text.count("(") != text.count(")"):
        fail(f"{path.relative_to(ROOT)} has unbalanced parentheses")


def check_info_json() -> None:
    info = json.loads(read("info.json"))
    scripts = set(info.get("scripts", []))
    missing_scripts = sorted(SCRIPT_REFS - scripts)
    if missing_scripts:
        fail(f"info.json missing scripts: {missing_scripts}")

    tweakdb = info.get("tweakdb", [])
    if isinstance(tweakdb, str):
        tweakdb = [tweakdb]
    missing_tweakdb = sorted(TWEAKDB_REFS - set(tweakdb))
    if missing_tweakdb:
        fail(f"info.json missing tweakdb refs: {missing_tweakdb}")

    for script in SCRIPT_REFS:
        if not (ROOT / "scripts" / script).exists():
            fail(f"info.json script path does not exist: scripts/{script}")
    for entry in TWEAKDB_REFS:
        if not (ROOT / entry).exists():
            fail(f"info.json tweakdb path does not exist: {entry}")


def check_redmod() -> None:
    redmod_text = read("redmod.toml")
    tomllib.loads(redmod_text)
    for ref in sorted(SCRIPT_REFS | TWEAKDB_REFS | COMMANDS):
        if ref not in redmod_text:
            fail(f"redmod.toml missing {ref}")


def check_cpmodproj() -> None:
    project = read("msn_integration.cpmodproj")
    for script in SCRIPT_REFS:
        xml_path = "scripts\\" + script.replace("/", "\\")
        if xml_path not in project:
            fail(f"msn_integration.cpmodproj missing {xml_path}")
    for entry in TWEAKDB_REFS:
        xml_path = entry.replace("/", "\\")
        if xml_path not in project:
            fail(f"msn_integration.cpmodproj missing {xml_path}")


def check_localization() -> None:
    loc = read("localization/en.stringlist")
    for key in sorted(LOCALIZATION_KEYS):
        if re.search(rf"^{re.escape(key)}\s*=", loc, re.MULTILINE) is None:
            fail(f"localization/en.stringlist missing {key}")


def check_scripts() -> None:
    scripts = sorted((ROOT / "scripts").rglob("*.reds"))
    for path in scripts:
        check_balanced(path)
        text = path.read_text()
        match = DATA_RECORD_PREFIX.search(text)
        if match:
            fail(f"{path.relative_to(ROOT)} contains data record prefix {match.group(0)!r}")

    magic = read("scripts/magic/msn_magic_system.reds")
    jedi = read("scripts/jedi/msn_jedi_system.reds")
    starwars = read("scripts/starwars/msn_starwars_system.reds")
    for symbol in ["MSNMagicSystem", "MSNMagicCerebellum", "CmdMagicCast"]:
        if symbol not in magic:
            fail(f"magic script missing {symbol}")
    for spell in MAGIC_SPELLS:
        if f'n"{spell}"' not in magic:
            fail(f"magic script missing runtime spell {spell}")
    for symbol in ["MSNJediSystem", "MSNLightsaberDiscipline", "CmdJediPower"]:
        if symbol not in jedi:
            fail(f"jedi script missing {symbol}")
    for power in JEDI_POWERS:
        if f'n"{power}"' not in jedi:
            fail(f"jedi script missing runtime power {power}")
    for symbol in ["StarWarsSystem", "MSNJediSystem.GetInstance", "CmdStarWarsStatus"]:
        if symbol not in starwars:
            fail(f"starwars compatibility wrapper missing {symbol}")


def check_tweakdb() -> None:
    stale_candidates = sorted(
        {
            p
            for p in (ROOT / "tweakdb").glob("*magic*.tweakdb")
            if p.relative_to(ROOT).as_posix() not in TWEAKDB_REFS
        }
        | {
            p
            for p in (ROOT / "tweakdb").glob("*jedi*.tweakdb")
            if p.relative_to(ROOT).as_posix() not in TWEAKDB_REFS
        }
    )
    stale = []
    for path in stale_candidates:
        rel = path.relative_to(ROOT).as_posix()
        if IGNORED_LEGACY_TWEAKDB_HASHES.get(rel) == sha256(path):
            continue
        stale.append(path)
    if stale:
        fail(
            "unmanifested active magic/Jedi tweakdb files: "
            + ", ".join(str(p.relative_to(ROOT)) for p in stale)
        )

    data = read("tweakdb/msn_magic_jedi.tweakdb")
    for record in [
        "Item:MSN_Arcane_Cerebellum",
        "Item:MSN_Arcane_Focus",
        "Item:MSN_Staff_of_Power",
        "Item:MSN_Wand_of_Fireballs",
        "Item:MSN_Force_Discipline_Implant",
        "Item:MSN_Plasma_Saber",
    ]:
        if record not in data:
            fail(f"tweakdb/msn_magic_jedi.tweakdb missing {record}")
    for spell in MAGIC_SPELLS:
        for fragment in (f"Ability:MSN_{spell}", f"msn.magic.cast {spell}"):
            if fragment not in data:
                fail(f"tweakdb/msn_magic_jedi.tweakdb missing {fragment}")
    for power in JEDI_POWERS:
        for fragment in (f"Ability:MSN_{power}", f"msn.jedi.power {power}"):
            if fragment not in data:
                fail(f"tweakdb/msn_magic_jedi.tweakdb missing {fragment}")


def main() -> int:
    check_info_json()
    check_redmod()
    check_cpmodproj()
    check_localization()
    check_scripts()
    check_tweakdb()
    print("OK: magic/Jedi REDmod surface validates")
    return 0


if __name__ == "__main__":
    sys.exit(main())
