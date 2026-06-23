import { api } from "@/lib/api";
import { Task } from "@/lib/api";

export default async function TasksPage() {
  let tasks: Task[] = [];
  try {
    tasks = await api.get<Task[]>("/tasks", { cache: "no-store" });
  } catch {}

  const statusColors: Record<string, string> = {
    completed: "text-green-400",
    in_progress: "text-blue-400",
    pending: "text-yellow-400",
    failed: "text-red-400",
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Tasks</h1>
      <div className="bg-card rounded-lg border border-border overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-muted/20">
            <tr>
              <th className="text-left p-3">Title</th>
              <th className="text-left p-3">Agent</th>
              <th className="text-left p-3">Status</th>
              <th className="text-left p-3">Priority</th>
              <th className="text-left p-3">Created</th>
            </tr>
          </thead>
          <tbody>
            {tasks.map((task) => (
              <tr key={task.id} className="border-t border-border">
                <td className="p-3">{task.title}</td>
                <td className="p-3 text-muted">{task.agent_type}</td>
                <td className={`p-3 ${statusColors[task.status] || ""}`}>{task.status}</td>
                <td className="p-3">{task.priority}</td>
                <td className="p-3 text-muted">{new Date(task.created_at).toLocaleDateString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
