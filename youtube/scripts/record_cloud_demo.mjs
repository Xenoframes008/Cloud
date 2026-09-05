import { mkdir } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { chromium } from "playwright-core";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const outDir = resolve(root, "out", "raw");
const targetUrl = process.env.CLOUD_URL ?? "http://127.0.0.1:3000";
const chromePath = process.env.CHROME_PATH ?? "/usr/local/bin/google-chrome";

await mkdir(outDir, { recursive: true });

const browser = await chromium.launch({
  executablePath: chromePath,
  headless: true,
  args: ["--hide-scrollbars"],
});

const context = await browser.newContext({
  viewport: { width: 1920, height: 1080 },
  deviceScaleFactor: 1,
  recordVideo: {
    dir: outDir,
    size: { width: 1920, height: 1080 },
  },
});

const page = await context.newPage();
page.setDefaultTimeout(20_000);

await page.goto(targetUrl, { waitUntil: "networkidle" });
await page.waitForSelector("#health");
await page.waitForFunction(() => {
  const health = document.getElementById("health")?.textContent ?? "";
  return health.includes("uptimeSeconds");
});

await page.waitForTimeout(5000);
await page.locator("#refresh").click();
await page.waitForTimeout(4500);
await page.locator("#refresh").click();
await page.waitForTimeout(4000);

const video = page.video();
await page.close();
const rawPath = await video.path();
await context.close();
await browser.close();

const dest = resolve(outDir, "cloud_app_raw.webm");
const { rename } = await import("node:fs/promises");
await rename(rawPath, dest);
console.log(dest);
