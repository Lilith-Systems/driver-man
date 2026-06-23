"use client";

import { useState, useEffect } from "react";
import { api } from "@/lib/api";
import { AgentStatus } from "@/lib/api";

const AGENT_LABELS: Record<string, string> = {
  orchestrator: "Orchestrator",
  business_planning: "Business Planning",
  competitor_research: "Competitor Research",
  social_media: "Social Media",
  ads_management: "Ads Management",
  email_outreach: "Email Outreach",
  code_generation: "Code Generation",
  customer_support: "Customer Support",
  finance: "Finance",
};

const AGENT_DESCRIPTIONS: Record<string, string> = {
  orchestrator: "Daily planning and performance review",
  business_planning: "Strategy, KPIs, and goal setting",
  competitor_research: "Web research and competitive intel",
  social_media: "Twitter content and engagement",
  ads_management: "Google & Meta campaign management",
  email_outreach: "Prospect finding and cold emails",
  code_generation: "Write, commit, and deploy code",
  customer_support: "Inbox monitoring and replies",
  finance: "Revenue tracking and Stripe sync",
};

export default function AgentsPage() {
  const [agents, setAgents] = useState<AgentStatus[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get<AgentStatus[]>("/agents/status").then((data) => {
      setAgents(data);
      setLoading(false);
    });
  }, []);

  const triggerAgent = async (type: string) => {
    await api.post(`/agents/${type}/trigger`, {});
    alert(`Agent ${AGENT_LABELS[type]} triggered!`);
  };

  if (loading) return <div>Loading agents...</div>;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">AI Agents</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {agents.map((agent) => (
          <div key={agent.agent_type} className="bg-card rounded-lg border border-border p-4 space-y-2">
            <h3 className="font-semibold text-lg">{AGENT_LABELS[agent.agent_type]}</h3>
            <p className="text-sm text-muted">{AGENT_DESCRIPTIONS[agent.agent_type]}</p>
            <div className="text-xs text-muted space-y-1">
              <p>Last run: {agent.last_run_at ? new Date(agent.last_run_at).toLocaleString() : "Never"}</p>
              <p>Status: {agent.last_run_status || "idle"}</p>
              <p>Tasks today: {agent.tasks_today} | Total: {agent.tasks_total}</p>
            </div>
            <button
              onClick={() => triggerAgent(agent.agent_type)}
              className="bg-primary text-white px-3 py-1.5 rounded text-sm hover:opacity-90"
            >
              Run Now
            </button>
          </div>
        ))}
      </div>
    </div>
  );
}
