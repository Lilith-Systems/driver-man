import { api } from "@/lib/api";

interface Prospect {
  id: number;
  email: string;
  first_name: string | null;
  last_name: string | null;
  company: string | null;
  title: string | null;
  status: string;
}

export default async function OutreachPage() {
  let prospects: Prospect[] = [];
  try {
    prospects = await api.get<Prospect[]>("/outreach/prospects", { cache: "no-store" });
  } catch {}

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Email Outreach</h1>
      <div className="bg-card rounded-lg border border-border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/20">
            <tr>
              <th className="text-left p-3">Name</th>
              <th className="text-left p-3">Email</th>
              <th className="text-left p-3">Company</th>
              <th className="text-left p-3">Status</th>
            </tr>
          </thead>
          <tbody>
            {prospects.map((p) => (
              <tr key={p.id} className="border-t border-border">
                <td className="p-3">{p.first_name} {p.last_name}</td>
                <td className="p-3 text-muted">{p.email}</td>
                <td className="p-3">{p.company}</td>
                <td className="p-3">{p.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
