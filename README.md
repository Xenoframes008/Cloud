# Cloud

A minimal Node.js + Express starter web application, used to bootstrap and
demonstrate the development environment.

## Requirements

- Node.js >= 20 (developed against Node 22)

## Getting started

```bash
npm install
npm start
```

The app then serves:

- `http://localhost:3000/` — a landing page that calls the API
- `GET /api/health` — service health and uptime
- `GET /api/info` — app metadata (name, Node version, platform)
- `POST /api/echo` — echoes back the JSON body you send

Set `PORT` to change the listening port (defaults to `3000`).

## Development

```bash
npm run dev    # start with auto-reload (node --watch)
npm test       # run the test suite (node --test)
```

## Project layout

```
src/app.js       Express app factory (routes, middleware)
src/server.js    Server entrypoint (binds host/port)
public/          Static assets (landing page)
test/            Automated tests (node:test)
```
