# PASUPASASTRA — Unified Command Center For Multi-drone Operations

| Folder | Isi |
|---|---|
| `app/` | Konsol GCS (Next.js 16 static export + Tauri 2), UI Bahasa Indonesia |
| `backend/` | `gcs-api` (FastAPI) dan `gcs-worker` (YOLO multi-model + Moondream) |
| `bridges/dji/` | Bridge Matrice 4T (Flutter + MSDK v5.17): telemetri, video, perintah, misi KMZ |
| `bridges/autel/` | Bridge EVO II V3 (Flutter + Autel SDK v1.5): telemetri, perintah, misi waypoint |
| `infra/` | Docker Compose, MediaMTX, Caddy, PM2, skrip setup Mac |
| `docs/` | Manual pengguna (PDF + sumber LaTeX), protokol bridge, hasil benchmark |

Mulai dari `docs/PASUPASASTRA-Manual-Pengguna.pdf`. Build ulang manual: `cd docs/manual && latexmk -xelatex manual.tex`.
