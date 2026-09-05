import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { createApp } from "../src/app.js";

let server;
let baseUrl;

before(async () => {
  const app = createApp();
  await new Promise((resolve) => {
    server = app.listen(0, "127.0.0.1", resolve);
  });
  const { port } = server.address();
  baseUrl = `http://127.0.0.1:${port}`;
});

after(() => {
  server?.close();
});

test("GET /api/health returns ok status", async () => {
  const res = await fetch(`${baseUrl}/api/health`);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.status, "ok");
  assert.ok(typeof body.uptimeSeconds === "number");
  assert.ok(typeof body.timestamp === "string");
});

test("GET /api/info returns app metadata", async () => {
  const res = await fetch(`${baseUrl}/api/info`);
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.equal(body.name, "Cloud");
  assert.equal(body.node, process.version);
});

test("POST /api/echo echoes the JSON body", async () => {
  const payload = { hello: "world", n: 42 };
  const res = await fetch(`${baseUrl}/api/echo`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify(payload),
  });
  assert.equal(res.status, 200);
  const body = await res.json();
  assert.deepEqual(body.youSent, payload);
});

test("GET / serves the landing page", async () => {
  const res = await fetch(`${baseUrl}/`);
  assert.equal(res.status, 200);
  const text = await res.text();
  assert.match(text, /<title>Cloud/);
});
