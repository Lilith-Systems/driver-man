import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";
import { Sidebar } from "@/components/layout/Sidebar";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Polsia — AI Business Agent",
  description: "Run your company on autopilot with 9 AI agents",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="antialiased selection:bg-primary selection:text-black">
        <div className="fixed inset-0 pointer-events-none z-[9999] bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-transparent via-transparent to-black/50 mix-blend-overlay"></div>
        <div className="scanline"></div>
        <div className="flex min-h-screen relative z-10">
          <Sidebar />
          <main className="flex-1 ml-14 p-6">{children}</main>
        </div>
      </body>
    </html>
  );
}
