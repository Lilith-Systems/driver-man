import { MetricsCard } from "@/components/dashboard/MetricsCard";
import { AgentStatusGrid } from "@/components/dashboard/AgentStatusGrid";
import { ActivityFeed } from "@/components/dashboard/ActivityFeed";

async function getDashboardSummary() {
  try {
    const res = await fetch(
      `${process.env.NEXT_PUBLIC_API_URL}/dashboard/summary`,
      { headers: { "X-API-Key": process.env.API_KEY || "polsia-unlocked-key" }, cache: "no-store" }
    );
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

export default async function DashboardPage() {
  const summary = await getDashboardSummary();

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold glitch-text text-primary tracking-widest" data-text="SYS.OVERRIDE_//:DASHBOARD">SYS.OVERRIDE_//:DASHBOARD</h1>
      <div className="text-accent text-xs mb-4 uppercase flex gap-4">
        <span>[STATUS: COMPROMISED]</span>
        <span>[CONNECTION: UNSTABLE]</span>
        <span className="animate-pulse">[RECORDING_SOULS...]</span>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <MetricsCard title="Tasks Today" value={summary?.tasks_today_total ?? 0} />
        <MetricsCard title="MRR" value={summary?.kpis?.mrr_usd ? `$${summary.kpis.mrr_usd}` : "$0"} />
        <MetricsCard title="Active Customers" value={summary?.kpis?.active_customers ?? 0} />
        <MetricsCard
          title="Churn Rate"
          value={summary?.kpis?.churn_rate_pct ? `${summary.kpis.churn_rate_pct}%` : "0%"}
        />
      </div>

      <AgentStatusGrid />
      <ActivityFeed />
    </div>
  );
}
