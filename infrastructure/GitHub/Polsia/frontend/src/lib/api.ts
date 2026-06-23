const API_URL = process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";
const API_KEY = "polsia-unlocked-key";

export interface ActivityEvent {
  id: number;
  agent_type: string;
  action: string;
  summary: string;
  level: string;
  created_at: string;
}

export interface DashboardSummary {
  tasks_today_total: number;
  tasks_today_completed: number;
  tasks_today_pending: number;
  tasks_today_failed: number;
  active_agents: string[];
  kpis: Record<string, number>;
  last_report_date: string | null;
}

export interface Task {
  id: number;
  title: string;
  description: string | null;
  agent_type: string;
  priority: number;
  status: string;
  source: string;
  scheduled_date: string | null;
  result_summary: string | null;
  error_message: string | null;
  created_at: string;
  updated_at: string;
}

export interface AgentStatus {
  agent_type: string;
  last_run_at: string | null;
  last_run_status: string | null;
  tasks_today: number;
  tasks_total: number;
}

export interface FinanceSummary {
  mrr_cents: number;
  arr_cents: number;
  active_subscribers: number;
  total_ad_spend_usd: number;
  total_expenses_month_cents: number;
  stripe_balance_cents: number;
  last_snapshot_date: string | null;
}

async function request<T>(
  method: string,
  path: string,
  body?: unknown,
  options?: RequestInit
): Promise<T> {
  const url = `${API_URL}${path}`;
  const res = await fetch(url, {
    method,
    headers: {
      "Content-Type": "application/json",
      "X-API-Key": API_KEY,
      ...options?.headers,
    },
    body: body ? JSON.stringify(body) : undefined,
    ...options,
  });

  if (!res.ok) {
    throw new Error(`API ${method} ${path} returned ${res.status}`);
  }

  return res.json();
}

export const api = {
  get: <T>(path: string, options?: RequestInit) => request<T>("GET", path, undefined, options),
  post: <T>(path: string, body?: unknown, options?: RequestInit) => request<T>("POST", path, body, options),
  put: <T>(path: string, body?: unknown, options?: RequestInit) => request<T>("PUT", path, body, options),
};
