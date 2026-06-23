#!/usr/bin/env python3
"""Generate the deterministic 10,000 item Abyssal hat catalog."""

from __future__ import annotations

from pathlib import Path


OUT = Path(__file__).resolve().parents[1] / "tweakdb/abyssal_hat_catalog.yaml"

LINES = [
    "schema: msn.abyssal_hat_catalog.v1",
    "localOnly: true",
    "generatedCount: 10000",
    "purpose: >",
    "  Deterministic story hats for Abyssal Assets, Nessie covenant, space",
    "  freighters, Javelin suits, business loops, and Cyberpunk armor sets.",
    "crafting:",
    "  skillTree: Haberdashery",
    "  business: Loch Exchange",
    "  currencies: [eddies, soulCoins, salvageCredits, nessieTreasuryMarks]",
    "  materials: [void_kelp_fiber, chrome_thread, sonar_pearl, pressure_silk, orbital_felt, blackwall_lace]",
    "sources:",
    "  - abyssal_skill_tree_quests",
    "  - one_world_space_economy",
    "  - procedural_space_systems",
    "  - freighter_javelin_business_systems",
    "rarityWeights:",
    "  Common: 5000",
    "  Uncommon: 2500",
    "  Rare: 1500",
    "  Epic: 750",
    "  Legendary: 220",
    "  Mythic: 30",
    "hatSets:",
    "  - id: set_loch_covenant",
    "    name: Loch Covenant Regalia",
    "    story: Respectful Nessie progression and guardian treasury rewards.",
    "  - id: set_orbital_haberdashery",
    "    name: Orbital Haberdashery",
    "    story: Salvage fashion from freighter crews and fighter pilots.",
    "  - id: set_javelin_crowns",
    "    name: Javelin Crowns",
    "    story: Suit-linked helmets, hoods, halos, cowls, and pilot caps.",
    "  - id: set_abyssal_business",
    "    name: Abyssal Business Formalwear",
    "    story: Loch Exchange traders, fleet brokers, and Soul Coin accountants.",
    "items:",
]

families = [
    ("Loch", "Nessie covenant", "set_loch_covenant", "sonar_pearl", "NessieFriendship"),
    ("Abyssal", "deep craft", "set_loch_covenant", "void_kelp_fiber", "AbyssalSkill"),
    ("Orbital", "freighter crew", "set_orbital_haberdashery", "orbital_felt", "FreighterOps"),
    ("Vector", "Javelin pilot", "set_javelin_crowns", "chrome_thread", "JavelinVector"),
    ("Bastion", "boarding tank", "set_javelin_crowns", "pressure_silk", "JavelinBastion"),
    ("Phantom", "interceptor ace", "set_javelin_crowns", "blackwall_lace", "JavelinPhantom"),
    ("Tempest", "storm artillery", "set_javelin_crowns", "sonar_pearl", "JavelinTempest"),
    ("Loch Exchange", "business formal", "set_abyssal_business", "chrome_thread", "LochExchange"),
    ("Nyx", "stealth logistics", "set_abyssal_business", "blackwall_lace", "NyxContracts"),
    ("Thoth", "ledger command", "set_abyssal_business", "orbital_felt", "ThothArchive"),
]

forms = [
    ("Cap", "HeadClothing"),
    ("Crown", "HeadClothing"),
    ("Helm", "HeadClothing"),
    ("Hood", "HeadClothing"),
    ("Beret", "HeadClothing"),
    ("Halo", "FaceClothing"),
    ("Cowl", "HeadClothing"),
    ("Pilot Hat", "HeadClothing"),
    ("Tricorne", "HeadClothing"),
    ("Beanie", "HeadClothing"),
]

tones = [
    ("Crimson", "Lilith"),
    ("Violet", "Lyra"),
    ("Abyssal", "Nessie"),
    ("Chrome", "NightCity"),
    ("Solar", "NomadLaunch"),
    ("Void", "Ouroboros"),
    ("Pearl", "Loch"),
    ("Blackwall", "OldNet"),
    ("Gold", "Kether"),
    ("Teal", "Aldecaldo"),
]

bonuses = [
    ("style", "StreetCredBonus", 0.01),
    ("power", "ArmorBonus", 1.0),
    ("fun", "DialogueFlavor", 1.0),
    ("business", "MarketFeeReduction", 0.001),
    ("space", "SalvageYieldBonus", 0.002),
]


def rarity(index: int) -> str:
    if index % 333 == 0:
        return "Mythic"
    if index % 47 == 0:
        return "Legendary"
    if index % 13 == 0:
        return "Epic"
    if index % 7 == 0:
        return "Rare"
    if index % 3 == 0:
        return "Uncommon"
    return "Common"


def main() -> None:
    lines = list(LINES)
    for idx in range(1, 10001):
        fam, lore, set_id, mat, unlock = families[(idx - 1) % len(families)]
        form, slot = forms[((idx - 1) // len(families)) % len(forms)]
        tone, affinity = tones[((idx - 1) // (len(families) * len(forms))) % len(tones)]
        bonus_kind, stat, base_value = bonuses[idx % len(bonuses)]
        item_id = f"Hat_Abyssal_{idx:05d}"
        value = round(base_value * (1 + (idx % 11) * 0.1), 4)
        lines.extend(
            [
                f"  - id: {item_id}",
                f"    displayName: \"{tone} {fam} {form} #{idx:05d}\"",
                f"    slot: {slot}",
                f"    rarity: {rarity(idx)}",
                f"    set: {set_id}",
                f"    storyRole: \"{lore} {form.lower()} for {bonus_kind} progression\"",
                f"    primaryMaterial: {mat}",
                f"    unlockFlag: {unlock}_Hat_{idx % 100:02d}",
                f"    affinity: {affinity}",
                "    stats:",
                f"      {stat}: {value}",
                f"    tags: [AbyssalAssets, Hat, {bonus_kind}, {fam.replace(' ', '')}, {tone}]",
            ]
        )
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUT} with 10000 hats")


if __name__ == "__main__":
    main()
