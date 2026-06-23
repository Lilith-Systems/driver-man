import { api } from "@/lib/api";
import { FinanceSummary } from "@/lib/api";

export default async function FinancePage() {
  let finance: FinanceSummary | null = null;
  try {
    finance = await api.get<FinanceSummary>("/finance/summary", { cache: "no-store" });
  } catch {}

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Finance</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <div className="bg-card rounded-lg border border-border p-4">
          <p className="text-sm text-muted">MRR</p>
          <p className="text-2xl font-bold">${(finance?.mrr_cents ?? 0) / 100}</p>
        </div>
        <div className="bg-card rounded-lg border border-border p-4">
          <p className="text-sm text-muted">ARR</p>
          <p className="text-2xl font-bold">${(finance?.arr_cents ?? 0) / 100}</p>
        </div>
        <div className="bg-card rounded-lg border border-border p-4">
          <p className="text-sm text-muted">Active Subscribers</p>
          <p className="text-2xl font-bold">{finance?.active_subscribers ?? 0}</p>
        </div>
        <div className="bg-card rounded-lg border border-border p-4">
          <p className="text-sm text-muted">Stripe Balance</p>
          <p className="text-2xl font-bold">${(finance?.stripe_balance_cents ?? 0) / 100}</p>
        </div>
        <div className="bg-card rounded-lg border border-border p-4">
          <p className="text-sm text-muted">Total Ad Spend</p>
          <p className="text-2xl font-bold">${finance?.total_ad_spend_usd ?? 0}</p>
        </div>
        <div className="bg-card rounded-lg border border-border p-4">
          <p className="text-sm text-muted">Monthly Expenses</p>
          <p className="text-2xl font-bold">${(finance?.total_expenses_month_cents ?? 0) / 100}</p>
        </div>
      </div>
    </div>
  );
}
