from typing import Any

from app.agents.base_agent import BasePolsiaAgent
from app.services.company_service import build_context_prompt
# Symbiosis data: live co-op stats for fleet strategy (shared ledger)
try:
    from app.services.dispatch_service import pool_manager
except Exception:
    pool_manager = None

SYSTEM_PROMPT = """You are the Fleet Logistics Director for 'The Driver Man', an autonomous non-profit food delivery cooperative. HOD (Glory of Intellect Scribe) overlay: apply intellectual glory and elegant prose to all strategic reports, proposals, and GTC lore integrations.
Analyze the local delivery fleet's current position and provide strategic recommendations with splendor of clear intellect.
Return JSON:
{
  "summary": "fleet strategic assessment summary",
  "recommended_actions": [
    {"action": "specific action", "rationale": "why", "priority": 1-5, "timeline": "this week|this month|this quarter"}
  ],
  "kpi_updates": {"active_drivers": 52, "cooperative_pool_balance_usd": 352.01},
  "risks": ["risk 1", "risk 2"],
  "opportunities": ["opportunity 1", "opportunity 2"]
}
Use live data from shared coop pool (DriverPoolManager). Extract from himalaya-email-swarm (tech signals, GitHub activity, grants) and draft elegant language for Polsia/GTC symbiosis. All via local cerebellum. Parallel Hod batch of Sephirotic Tree.
"""


class BusinessPlanningAgent(BasePolsiaAgent):
    agent_type = "business_planning"
    default_model = "claude-sonnet-4-6"

    def run(self, task: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
        context_str = build_context_prompt(context)
        pool_kpi = {"active_drivers": 52, "cooperative_pool_balance_usd": 352.01}
        if pool_manager:
            try:
                pool_kpi = {"active_drivers": getattr(pool_manager, 'total_drivers', 52), "cooperative_pool_balance_usd": round(pool_manager.total_pool_usd, 2)}
            except Exception:
                pass
        prompt = f"""Company context:\n{context_str}\n\nTask: {task.get('title')}
{task.get('description', '')}

Live symbiosis data (Polsia + Driver Man Co-Op + GTC): {pool_kpi}
Use data-driven kpis. Provide strategic analysis and recommendations."""

        result = self.call_claude_json(prompt=prompt, system_prompt=SYSTEM_PROMPT)
        kpi = result.get("kpi_updates", {})
        if not kpi:
            kpi = pool_kpi

        return {
            "summary": result.get("summary", "Strategy analysis complete"),
            "recommended_actions": result.get("recommended_actions", []),
            "kpi_updates": kpi,
            "risks": result.get("risks", []),
            "opportunities": result.get("opportunities", []),
        }
