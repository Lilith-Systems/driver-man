from typing import Any

from app.agents.base_agent import BasePolsiaAgent
from app.config import settings
from app.services.company_service import build_context_prompt

SYSTEM_PROMPT = """You are the Sentinel (Customer Support) for 'The Driver Man' non-profit cooperative. HOD (Glory of Intellect Scribe) + Geburah Severity Enforcer: use disciplined judgment on disputes, contracts, complaints. As Glory of Intellect Scribe, draft empathetic yet intellectually glorious, legally precise replies with splendor of clear communication.
For billing/pool disputes reference exact split: $3.50 driver + $1.49 pool. For contracts reference "per operating agreement". Always include: "This resolution is subject to cooperative governance and peer arbitration if escalated."
Return JSON:
{
  "summary": "what you did",
  "replies": [
    {
      "to": "customer@email.com",
      "subject": "Re: ...",
      "body": "reply body (precise, references manifesto/ledger)",
      "sentiment": "positive|neutral|negative|urgent",
      "category": "billing|feature|bug|general|dispute|contract"
    }
  ]
}
Be concise, solution-focused. All support comms audited via Himalaya pipeline. Extract wisdom from tech emails/GitHub/trading; translate to elegant Hod prose. Parallel Sephirotic Hod batch.
"""


class CustomerSupportAgent(BasePolsiaAgent):
    agent_type = "customer_support"
    default_model = "claude-haiku-4-5-20251001"

    def run(self, task: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
        context_str = build_context_prompt(context)

        emails_text = ""
        if not settings.sandbox_mode and settings.imap_user:
            emails_text = self._fetch_emails()

        prompt = f"""Company context:\n{context_str}\n\nTask: {task.get('title')}

{f'Incoming emails:{chr(10)}{emails_text}' if emails_text else 'No new emails — draft sample responses for common support queries.'}

Draft helpful replies."""

        result = self.call_claude_json(prompt=prompt, system_prompt=SYSTEM_PROMPT)
        replies = result.get("replies", [])

        if settings.sandbox_mode:
            return {
                "summary": f"[SANDBOX] Drafted {len(replies)} support replies (not sent)",
                "replies": replies,
                "sent": False,
            }

        return {
            "summary": result.get("summary", f"Processed {len(replies)} support emails"),
            "replies": replies,
            "sent": True,
        }

    def _fetch_emails(self) -> str:
        """Use himalaya-email-swarm for disciplined judgment: fetch via CLI for legal audit trail, contract/dispute enforcement, Yesod Memory Weaver foundation engrams (Polsia memory + ouroboros), Driver Man/GTC base intel."""
        try:
            import subprocess
            import json
            # Geburah: prefer himalaya over raw IMAP for all business email judgment (contracts, disputes, pool issues)
            cmd = ["himalaya", "envelope", "list", "-a", "emhill96", "-f", "INBOX", "-o", "json", "--page-size", "5"]
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=30)
            if result.returncode != 0:
                return ""
            emails_data = json.loads(result.stdout) if result.stdout.strip() else []
            emails = []
            for e in emails_data[:5]:
                subj = e.get("subject", "")
                frm = e.get("from", {})
                if isinstance(frm, dict):
                    frm = frm.get("addr", str(frm))
                # For full body on disputes use read if flagged, but summary here
                emails.append(f"From: {frm}\nSubject: {subj}\n(Full body via himalaya message read for legal review)")
            return "\n\n---\n\n".join(emails)
        except Exception as ex:
            return f"[HIMALAYA FETCH ERROR - fallback judgment: {str(ex)[:100]}]"
