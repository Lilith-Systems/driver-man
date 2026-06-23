"use client";

import { useAgentStatus } from "@/hooks/useAgentStatus";

const AGENT_LABELS: Record<string, string> = {
  orchestrator: "Orchestrator",
  business_planning: "Planning",
  competitor_research: "Research",
  social_media: "Social",
  ads_management: "Ads",
  email_outreach: "Outreach",
  code_generation: "Code",
  customer_support: "Support",
  finance: "Finance",
};

export function AgentStatusGrid() {
  const { agents, loading } = useAgentStatus();

  if (loading) {
    return (
      <div className="grid grid-cols-3 gap-4">
        {Array.from({ length: 9 }).map((_, i) => (
          <div key={i} className="terminal-box rounded-sm p-3 animate-pulse">
            <div className="h-4 bg-muted/40 rounded-sm w-20 mb-2" />
            <div className="h-3 bg-muted/40 rounded-sm w-12" />
          </div>
        ))}
      </div>
    );
  }

  const statusColor = (status: string | null) => {
    switch (status) {
      case "completed": return "text-accent text-shadow-accent";
      case "running": return "text-primary animate-pulse";
      case "failed": return "text-red-500 glitch-text";
      default: return "text-muted";
    }
  };

  return (
    <div className="grid grid-cols-3 gap-4">
      {agents.map((agent) => (
        <div key={agent.agent_type} className="terminal-box rounded-sm p-3 hover:border-primary transition-colors relative overflow-hidden">
          <div className="absolute -right-4 -top-4 w-12 h-12 bg-primary/10 rounded-full blur-xl"></div>
          <p className="text-xs tracking-widest font-bold text-foreground uppercase">{AGENT_LABELS[agent.agent_type] || agent.agent_type}</p>
          <p className={`text-xs mt-2 font-bold uppercase tracking-widest ${statusColor(agent.last_run_status)}`} data-text={agent.last_run_status || "idle"}>
            [{agent.last_run_status || "idle"}]
          </p>
          <p className="text-[10px] text-muted mt-2 border-t border-border/50 pt-1">
            OPS: {agent.tasks_today.toString().padStart(4, '0')}
          </p>
        </div>
      ))}
    </div>
  );
}
