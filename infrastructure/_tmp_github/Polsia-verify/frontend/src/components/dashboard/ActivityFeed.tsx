"use client";

import { useActivityFeed } from "@/hooks/useActivityFeed";

const levelColors: Record<string, string> = {
  info: "bg-primary shadow-[0_0_8px_rgba(255,0,255,0.8)]",
  success: "bg-accent shadow-[0_0_8px_rgba(57,255,20,0.8)]",
  warning: "bg-yellow-400 shadow-[0_0_8px_rgba(250,204,21,0.8)]",
  error: "bg-red-500 shadow-[0_0_8px_rgba(239,68,68,0.8)]",
};

export function ActivityFeed() {
  const { events, connected } = useActivityFeed();

  return (
    <div className="terminal-box rounded-sm p-4 relative overflow-hidden">
      <div className="absolute top-0 left-0 w-full h-[1px] bg-primary/50 shadow-[0_0_10px_rgba(255,0,255,0.8)]"></div>
      <div className="flex items-center justify-between mb-4 border-b border-primary/30 pb-2">
        <h2 className="font-bold text-primary tracking-widest uppercase glitch-text" data-text="SYSTEM.LOG">SYSTEM.LOG</h2>
        <span className={`text-[10px] uppercase font-bold tracking-widest px-2 py-0.5 rounded-sm border ${
          connected ? "bg-accent/10 text-accent border-accent/50 animate-pulse" : "bg-red-500/10 text-red-500 border-red-500/50"
        }`}>
          {connected ? "[UPLINK_ESTABLISHED]" : "[UPLINK_SEVERED]"}
        </span>
      </div>

      <div className="space-y-3 max-h-64 overflow-y-auto pr-2 custom-scrollbar">
        {events.map((event) => (
          <div key={event.id} className="flex items-start gap-3 text-xs border-l border-primary/20 pl-2 hover:bg-primary/5 p-1 transition-colors">
            <span className={`w-2 h-2 rounded-none mt-1 flex-shrink-0 ${levelColors[event.level] || "bg-primary"}`} />
            <div>
              <p className="text-muted text-[10px] font-bold tracking-widest uppercase">[{event.agent_type}]</p>
              <p className="text-foreground tracking-wide">{event.summary}</p>
            </div>
          </div>
        ))}
        {events.length === 0 && (
          <p className="text-muted text-xs uppercase animate-pulse">Awaiting incoming signals...</p>
        )}
      </div>
    </div>
  );
}
