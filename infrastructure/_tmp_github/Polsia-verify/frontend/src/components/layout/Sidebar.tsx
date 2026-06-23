"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard, Bot, ListChecks, Share2, Mail, Megaphone,
  DollarSign, Brain, Settings,
} from "lucide-react";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/agents", label: "Agents", icon: Bot },
  { href: "/tasks", label: "Tasks", icon: ListChecks },
  { href: "/social", label: "Social", icon: Share2 },
  { href: "/outreach", label: "Outreach", icon: Mail },
  { href: "/ads", label: "Ads", icon: Megaphone },
  { href: "/finance", label: "Finance", icon: DollarSign },
  { href: "/memory", label: "Memory", icon: Brain },
  { href: "/settings", label: "Settings", icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <nav className="fixed left-0 top-0 bottom-0 w-14 bg-card/90 backdrop-blur-md border-r border-primary/30 flex flex-col items-center py-4 gap-4 z-50 shadow-[0_0_15px_rgba(255,0,255,0.2)]">
      <div className="text-accent font-bold text-lg mb-4 glitch-text" data-text="P_">P_</div>
      {navItems.map((item) => {
        const Icon = item.icon;
        const active = pathname.startsWith(item.href);
        return (
          <Link
            key={item.href}
            href={item.href}
            title={item.label}
            className={`p-2 rounded-sm transition-all duration-300 relative group overflow-hidden ${
              active
                ? "bg-primary/20 text-primary shadow-[inset_0_0_10px_rgba(255,0,255,0.5)] border border-primary/50"
                : "text-muted hover:text-accent hover:bg-accent/10 hover:shadow-[0_0_10px_rgba(57,255,20,0.5)] border border-transparent"
            }`}
          >
            <div className={`absolute inset-0 bg-gradient-to-r from-transparent via-primary/20 to-transparent -translate-x-full group-hover:animate-[scanline_2s_linear_infinite]`}></div>
            <Icon size={18} className="relative z-10" />
          </Link>
        );
      })}
    </nav>
  );
}
