"use client";

import { useState, useEffect, useRef } from "react";
import { api, AgentStatus } from "@/lib/api";

export function useAgentStatus(pollInterval = 30000) {
  const [agents, setAgents] = useState<AgentStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    const fetchStatus = async () => {
      try {
        const data = await api.get<AgentStatus[]>("/agents/status");
        if (!cancelled) {
          setAgents(data);
          setLoading(false);
          setError(null);
        }
      } catch (err) {
        if (!cancelled) {
          setError("Failed to fetch agent status");
          setLoading(false);
        }
      }
    };

    fetchStatus();
    const interval = setInterval(fetchStatus, pollInterval);

    return () => {
      cancelled = true;
      clearInterval(interval);
    };
  }, [pollInterval]);

  return { agents, loading, error };
}
