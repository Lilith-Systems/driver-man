interface MetricsCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  trend?: "up" | "down";
  loading?: boolean;
}

export function MetricsCard({ title, value, subtitle, trend, loading }: MetricsCardProps) {
  if (loading) {
    return (
      <div className="terminal-box p-4 animate-pulse rounded-sm">
        <div className="h-4 bg-muted/40 rounded-sm w-24 mb-2" />
        <div className="h-8 bg-muted/40 rounded-sm w-16" />
      </div>
    );
  }

  return (
    <div className="terminal-box p-4 rounded-sm relative group overflow-hidden transition-all hover:border-accent">
      <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-primary/50 to-transparent opacity-0 group-hover:opacity-100 transition-opacity"></div>
      <p className="text-xs text-muted font-bold tracking-widest uppercase mb-1">{title}</p>
      <p className="text-2xl font-bold text-foreground glitch-text" data-text={value}>{value}</p>
      {subtitle && (
        <p className={`text-xs mt-2 uppercase tracking-wider ${trend === "up" ? "text-accent" : trend === "down" ? "text-red-500" : "text-muted"}`}>
          {trend === "up" ? "▲ " : trend === "down" ? "▼ " : "■ "}{subtitle}
        </p>
      )}
    </div>
  );
}
