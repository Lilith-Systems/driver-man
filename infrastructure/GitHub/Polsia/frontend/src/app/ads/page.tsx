import { api } from "@/lib/api";

interface AdCampaign {
  id: number;
  platform: string;
  name: string;
  goal: string | null;
  status: string;
  daily_budget_usd: number;
  total_spent_usd: number;
}

export default async function AdsPage() {
  let campaigns: AdCampaign[] = [];
  try {
    campaigns = await api.get<AdCampaign[]>("/ads/campaigns", { cache: "no-store" });
  } catch {}

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Ad Campaigns</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {campaigns.map((c) => (
          <div key={c.id} className="bg-card rounded-lg border border-border p-4">
            <h3 className="font-semibold">{c.name}</h3>
            <div className="text-sm text-muted space-y-1 mt-2">
              <p>Platform: {c.platform}</p>
              <p>Status: {c.status}</p>
              <p>Budget: ${c.daily_budget_usd}/day</p>
              <p>Spent: ${c.total_spent_usd}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
