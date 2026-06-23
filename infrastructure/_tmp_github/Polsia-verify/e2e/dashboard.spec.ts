import { test, expect } from "@playwright/test";

test("dashboard loads and shows metrics", async ({ page }) => {
  await page.goto("/dashboard");
  await expect(page.locator("text=Dashboard")).toBeVisible();
  await expect(page.locator("text=Tasks Today")).toBeVisible();
});

test("sidebar navigation is present", async ({ page }) => {
  await page.goto("/dashboard");
  await expect(page.locator('[title="Agents"]')).toBeVisible();
  await expect(page.locator('[title="Settings"]')).toBeVisible();
});
