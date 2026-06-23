import { test, expect } from "@playwright/test";

test("settings form loads", async ({ page }) => {
  await page.goto("/settings");
  await expect(page.locator("text=Company Name")).toBeVisible();
});

test("save button is present", async ({ page }) => {
  await page.goto("/settings");
  await expect(page.locator("text=Save Settings")).toBeVisible();
});
