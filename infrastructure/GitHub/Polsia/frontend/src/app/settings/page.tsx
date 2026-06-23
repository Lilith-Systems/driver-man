"use client";

import { useState, useEffect, FormEvent } from "react";
import { api } from "@/lib/api";

interface CompanyConfig {
  id: number;
  name: string;
  mission: string | null;
  vision: string | null;
  description: string | null;
  target_market: string | null;
  value_prop: string | null;
  website_url: string | null;
  industry: string | null;
  timezone: string;
  daily_cycle_hour: number;
}

export default function SettingsPage() {
  const [config, setConfig] = useState<CompanyConfig | null>(null);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({
    name: "", mission: "", vision: "", description: "",
    target_market: "", value_prop: "", website_url: "", industry: "",
    timezone: "UTC", daily_cycle_hour: 6,
  });

  useEffect(() => {
    api.get<CompanyConfig>("/config").then((data) => {
      setConfig(data);
      setForm({
        name: data.name || "",
        mission: data.mission || "",
        vision: data.vision || "",
        description: data.description || "",
        target_market: data.target_market || "",
        value_prop: data.value_prop || "",
        website_url: data.website_url || "",
        industry: data.industry || "",
        timezone: data.timezone || "UTC",
        daily_cycle_hour: data.daily_cycle_hour || 6,
      });
    }).catch(() => setConfig(null));
  }, []);

  const save = async (e: FormEvent) => {
    e.preventDefault();
    setSaving(true);
    try {
      const updated = await api.put<CompanyConfig>("/config", form);
      setConfig(updated);
      alert("Settings saved!");
    } catch {
      alert("Failed to save settings");
    }
    setSaving(false);
  };

  const field = (label: string, key: string, type = "text") => (
    <div>
      <label className="block text-sm text-muted mb-1">{label}</label>
      <input
        type={type}
        value={(form as any)[key] || ""}
        onChange={(e) => setForm({ ...form, [key]: e.target.value })}
        className="w-full bg-card border border-border rounded px-3 py-2 text-sm"
      />
    </div>
  );

  return (
    <div className="space-y-6 max-w-2xl">
      <h1 className="text-2xl font-bold">Settings</h1>
      <form onSubmit={save} className="space-y-4">
        {field("Company Name", "name")}
        {field("Mission", "mission")}
        {field("Vision", "vision")}
        {field("Description", "description")}
        {field("Target Market", "target_market")}
        {field("Value Proposition", "value_prop")}
        {field("Website URL", "website_url")}
        {field("Industry", "industry")}
        {field("Timezone", "timezone")}
        {field("Daily Cycle Hour (0-23)", "daily_cycle_hour", "number")}

        <button
          type="submit"
          disabled={saving}
          className="bg-primary text-white px-6 py-2 rounded hover:opacity-90"
        >
          {saving ? "Saving..." : "Save Settings"}
        </button>
      </form>
    </div>
  );
}
