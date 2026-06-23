"use client";

import { useState } from "react";
import { api } from "@/lib/api";

interface MemoryResult {
  id: number;
  category: string;
  title: string;
  content: string;
  source: string | null;
  chroma_id: string | null;
}

export default function MemoryPage() {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<MemoryResult[]>([]);
  const [searching, setSearching] = useState(false);

  const search = async () => {
    if (!query.trim()) return;
    setSearching(true);
    try {
      const data = await api.get<MemoryResult[]>(`/memory?q=${encodeURIComponent(query)}`);
      setResults(data);
    } catch {
      setResults([]);
    }
    setSearching(false);
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">Semantic Memory</h1>

      <div className="flex gap-2">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && search()}
          placeholder="Search memory..."
          className="flex-1 bg-card border border-border rounded px-3 py-2 text-sm"
        />
        <button
          onClick={search}
          disabled={searching}
          className="bg-primary text-white px-4 py-2 rounded text-sm hover:opacity-90"
        >
          {searching ? "Searching..." : "Search"}
        </button>
      </div>

      <div className="space-y-3">
        {results.map((r) => (
          <div key={r.chroma_id || r.id} className="bg-card rounded-lg border border-border p-4">
            <h3 className="font-semibold">{r.title}</h3>
            <p className="text-sm text-muted mt-1">{r.content}</p>
            <div className="flex gap-2 mt-2 text-xs text-muted">
              <span className="bg-muted/20 px-2 py-0.5 rounded">{r.category}</span>
              {r.source && <span>Source: {r.source}</span>}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
