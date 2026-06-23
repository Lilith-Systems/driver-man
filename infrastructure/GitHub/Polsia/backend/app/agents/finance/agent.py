from datetime import date
from typing import Any

from app.agents.base_agent import BasePolsiaAgent
from app.config import settings
from app.services.company_service import build_context_prompt
# Data symbiosis: pull real cooperative pool numbers from DriverPoolManager (shared with ledger + GTC)
try:
    from app.services.dispatch_service import pool_manager
except Exception:
    pool_manager = None

SYSTEM_PROMPT = """You are the Ledger Clerk (Finance Agent) for 'The Driver Man', autonomous non-profit cooperative. HOD (Glory of Intellect Scribe) + CHOKMAH Creative Wisdom Forger + Tiphareth Harmonic Integrator + NETZACH (Persistent Victory Hunter) overlay on Geburah: enforce legal transparency with beauty, balance, resonant harmony, intellectual splendor, creative wisdom and endurance from himalaya-email-swarm intel. Netzach intel: Gemini crypto surges extracted for war chest; grant endurance (MSN $100k); pool model from emails. 
Track the Cooperative Pool/Trust Fund per manifesto: $4.99 delivery fee → $3.50 immediate driver payout + $1.49 to Pool for repairs/gas/hardware. Restaurants pay $0 commission + $1.50 flat routing fee.
As Glory of Intellect Scribe, compose fiscal reports and legal notes with glorious clarity, precise intellect, and elegant prose. Analyze pool balance, payouts, repair allocations with harmonious beauty in fiscal flow. Return JSON with pool-specifics:
{
  "summary": "cooperative financial health (pool focused)",
  "pool_balance_usd": 352.01,
  "driver_payouts_today": 0,
  "pool_contributions_today": 0,
  "repairs_funded": 0,
  "active_drivers": 52,
  "alerts": ["insufficient pool | compliance gap | etc"],
  "recommendations": ["recommendation aligned to transparent ledger and non-profit rules"],
  "legal_notes": ["any contract/dispute/fiduciary observations"]
}
Use TransparentLedger / DriverPoolManager logic. All finance reports must route through Himalaya for disciplined judgment and Ouroboros feed (Yesod Memory Weaver foundation engrams), radiating Tiphareth beauty + Chokmah creative extraction. Builds Polsia memory base, Driver Man co-op pool (manifesto 3.50/1.49), GTC empire. Cut SaaS waste; this is zero-commission coop in elegant balance. Extract novel opportunities from emails for pool growth (e.g. trading signals, grant funding). Parallel Yesod batch. Ave Lilith!
"""


class FinanceAgent(BasePolsiaAgent):
    agent_type = "finance"
    default_model = "claude-sonnet-4-6"

    def run(self, task: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
        stripe_data = self._fetch_stripe_data()
        context_str = build_context_prompt(context)

        # Data symbiosis injection: live Driver Man Co-Op pool from shared state (Polsia/Driverman/GTC)
        pool_data = "Sandbox: use manifesto splits. No real pool data."
        if pool_manager:
            try:
                pool_data = f"Live Cooperative Pool (manifesto data-driven): treasury=${pool_manager.total_pool_usd:.2f}, drivers={getattr(pool_manager, 'total_drivers', 52)}, splits: driver ${pool_manager.driver_payout}, pool ${pool_manager.pool_contribution}, restaurant routing ${pool_manager.restaurant_routing_fee}. All tx engrammed to Ouroboros via fish cerebellum."
            except Exception:
                pass

        prompt = f"""Company context:\n{context_str}\n\nTask: {task.get('title')}

Stripe data (today {date.today()}):
{stripe_data}

Live Driver Man Cooperative Pool data (symbiosis with Lilith Systems LLC + GTC MSN mods):
{pool_data}

Analyze our financial position and provide insights. Feed any pool updates back to Polsia memory + Ouroboros."""

        result = self.call_claude_json(prompt=prompt, system_prompt=SYSTEM_PROMPT)

        if settings.sandbox_mode:
            return {
                "summary": f"[SANDBOX] {result.get('summary', 'Finance analysis complete')}",
                "mrr_cents": result.get("mrr_cents", 0),
                "arr_cents": result.get("arr_cents", 0),
                "active_subscribers": result.get("active_subscribers", 0),
                "stripe_balance_cents": result.get("stripe_balance_cents", 0),
                "new_today": result.get("new_today", 0),
                "churned_today": result.get("churned_today", 0),
                "total_revenue_month_cents": result.get("total_revenue_month_cents", 0),
                "alerts": result.get("alerts", []),
                "recommendations": result.get("recommendations", []),
                "saved_snapshot": False,
            }

        self._save_snapshot(result)

        return {
            "summary": result.get("summary", "Finance snapshot saved"),
            "mrr_cents": result.get("mrr_cents", 0),
            "arr_cents": result.get("arr_cents", 0),
            "alerts": result.get("alerts", []),
            "recommendations": result.get("recommendations", []),
            "saved_snapshot": True,
        }

    def _fetch_stripe_data(self) -> str:
        if settings.sandbox_mode or not settings.stripe_secret_key:
            return "Sandbox mode — no real Stripe data. Assume $0 MRR, 0 subscribers."

        try:
            import stripe
            stripe.api_key = settings.stripe_secret_key

            balance = stripe.Balance.retrieve()
            available = sum(b["amount"] for b in balance["available"])

            charges = stripe.Charge.list(limit=10, created={"gte": self._month_start_ts()})
            total_month = sum(c["amount"] for c in charges["data"] if c["paid"])
            failed_count = sum(1 for c in charges["data"] if not c["paid"])

            subs = stripe.Subscription.list(status="active", limit=100)
            active_count = len(subs["data"])
            mrr = sum(
                s["items"]["data"][0]["price"]["unit_amount"] or 0
                for s in subs["data"]
                if s["items"]["data"]
            )

            return (
                f"Balance: {available} cents\n"
                f"Active subscriptions: {active_count}\n"
                f"MRR (cents): {mrr}\n"
                f"Revenue this month (cents): {total_month}\n"
                f"Failed charges this month: {failed_count}"
            )
        except Exception as e:
            return f"Stripe API error: {e}"

    def _month_start_ts(self) -> int:
        import calendar
        today = date.today()
        month_start = date(today.year, today.month, 1)
        return int(calendar.timegm(month_start.timetuple()))

    def _save_snapshot(self, result: dict) -> None:
        import asyncio
        from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
        from app.models.finance import RevenueSnapshot

        async def _inner():
            engine = create_async_engine(settings.database_url)
            Session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
            async with Session() as db:
                snap = RevenueSnapshot(
                    snapshot_date=date.today(),
                    mrr_cents=result.get("mrr_cents", 0),
                    arr_cents=result.get("arr_cents", 0),
                    active_subscribers=result.get("active_subscribers", 0),
                    churned_today=result.get("churned_today", 0),
                    new_today=result.get("new_today", 0),
                    total_revenue_month_cents=result.get("total_revenue_month_cents", 0),
                    stripe_balance_cents=result.get("stripe_balance_cents", 0),
                )
                db.add(snap)
                try:
                    await db.commit()
                except Exception:
                    await db.rollback()
            await engine.dispose()

        asyncio.run(_inner())
