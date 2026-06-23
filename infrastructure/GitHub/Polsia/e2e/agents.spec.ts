import { test, expect } from "@playwright/test";

test("agent list displays and has run buttons", async ({ page }) => {
  await page.goto("/agents");
  await expect(page.locator("text=Run Now").first()).toBeVisible();
});

test("trigger agent opens confirmation", async ({ page }) => {
  await page.goto("/agents");
  await page.locator("text=Run Now").first().click();
  await expect(page.locator("text=triggered")).toBeVisible();
});
