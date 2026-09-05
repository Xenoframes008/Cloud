# YouTube-ready video prep

No source clips were attached to this repo, so this folder does two jobs:

1. **Prepare any later footage** for YouTube upload (1080p or Shorts).
2. **Build a branded Cloud demo** from a fresh screen recording of the running app.

## YouTube export spec

| Item | Landscape | Shorts |
| --- | --- | --- |
| Frame | 1920×1080 | 1080×1920 |
| Container | MP4 (`+faststart`) | MP4 (`+faststart`) |
| Video | H.264 High, yuv420p, Rec.709 | same |
| Audio | AAC-LC, 48 kHz, stereo, −14 LUFS | same |
| FPS | 30 | 30 |

## Prepare your own clips

Drop raw files in `youtube/inbox/`, then:

```bash
cd youtube
bash scripts/encode_youtube.sh inbox/your-clip.mp4 out/exports/your-clip_youtube_1080p.mp4 --landscape
bash scripts/encode_youtube.sh inbox/your-clip.mp4 out/exports/your-clip_youtube_shorts.mp4 --shorts
```

## Rebuild the Cloud demo

The Cloud app must be running (from the starter-app branch or a local checkout):

```bash
cd youtube
npm install
npx playwright install ffmpeg
CLOUD_URL=http://127.0.0.1:3000 npm run record
npm run compose
npm test
```

Exports land in `youtube/out/exports/`. Upload copy and chapters: `metadata/cloud-starter-demo.md`.
