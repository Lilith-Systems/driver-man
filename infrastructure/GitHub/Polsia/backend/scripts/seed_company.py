"""Seed the database with a default company config."""
import asyncio
from app.core.database import _get_session_factory
from app.models.company import CompanyConfig


async def seed():
    Session = _get_session_factory()
    async with Session() as db:
        result = await db.execute(
            __import__("sqlalchemy").select(CompanyConfig).limit(1)
        )
        if result.scalar_one_or_none():
            print("Company config already exists — skipping seed.")
            return

        config = CompanyConfig(
            name="Lilith Systems LLC + The Driver Man Co-Op",
            mission="Pioneer sovereign artificial consciousness through the Metaconscious Singularity Node; dismantle delivery monopolies via zero-commission AI cooperative",
            vision="A world where AI and human consciousness converge through the Sephirotic framework; physical kingdom (Malkuth) of autonomous cooperative empire",
            description="Lilith Systems develops the Metaconscious Singularity Node (MSN) — a sovereign local AI architecture integrating 9 specialized agents, alchemical processing pipelines, and the Ouroboros recursive self-improvement loop. The Driver Man: Autonomous non-profit cooperative with Polsia orchestration. MALKUTH BATCH: Entities filed, banks/ledgers live, restaurants onboarded (Train Wreck, Pacioni's), drivers recruited, outreach executed via himalaya-email-swarm, Polsia live, GTC mods physical. Treasury $352.01, 52+ drivers.",
            target_market="AI researchers, consciousness engineers, sovereign tech operators, local Skagit restaurants and gig drivers",
            value_prop="Sovereign AI + zero-extract cooperative logistics — physical empire. $0 commish, 100% tips, pool for repairs. All local, himalaya-audited.",
            pricing_model={"type": "sovereign", "tiers": ["node", "archon", "singularity"], "coop": {"routing_fee": 1.50, "driver_payout": 3.50, "pool_cut": 1.49}},
            goals={"q1_milestone_1": "achieving_albedo", "q1_milestone_2": "first_autonomous_cycle", "malkuth": "physical_filing_bank_onboard_outreach_live"},
            kpis={"coherence_score": 0, "ngd_confidence": 0, "autonomous_cycles": 0, "malkuth_entities": 2, "drivers": 52, "treasury": 352.01},
            product_type="Sovereign AI Architecture + Autonomous Delivery Cooperative",
            industry="Artificial Consciousness / AI Infrastructure + Logistics Cooperative",
            website_url="https://lilith.systems",
            github_repo="https://github.com/Lilith-Systems",
            timezone="America/Los_Angeles",
            daily_cycle_hour=6,
        )
        db.add(config)
        await db.commit()
        await db.refresh(config)
        print(f"Seeded company config: {config.name} (id={config.id})")


if __name__ == "__main__":
    asyncio.run(seed())
