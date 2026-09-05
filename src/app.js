import express from "express";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));

const START_TIME = Date.now();

export function createApp() {
  const app = express();

  app.use(express.json());
  app.use(express.static(join(__dirname, "..", "public")));

  app.get("/api/health", (_req, res) => {
    res.json({
      status: "ok",
      uptimeSeconds: Math.round((Date.now() - START_TIME) / 1000),
      timestamp: new Date().toISOString(),
    });
  });

  app.get("/api/info", (_req, res) => {
    res.json({
      name: "Cloud",
      description: "A minimal Node.js + Express starter web application.",
      node: process.version,
      platform: process.platform,
    });
  });

  app.post("/api/echo", (req, res) => {
    res.json({ youSent: req.body ?? null });
  });

  return app;
}
