import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: ".",
  timeout: 30000,
  retries: 1,
  use: {
    baseURL: "http://localhost:80",
    extraHTTPHeaders: { "X-API-Key": "polsia-unlocked-key" },
  },
  projects: [{ name: "chromium", use: { browserName: "chromium" } }],
  reporter: "html",
});
