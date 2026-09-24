# Deploy — Mac Mini M4 (home server)

Arsitektur: **Docker** untuk MediaMTX, TimescaleDB, NATS, API, dan web (Caddy);
**native (PM2)** untuk worker inferensi + Ollama agar bisa memakai CoreML/Metal dan VideoToolbox.

## 1. Sekali saja
```bash
./infra/scripts/setup-mac.sh             # ffmpeg, python 3.12 venv, ollama pull moondream + llama3.2:3b, pm2
cd infra && cp .env.example .env         # isi LAN_IP, POSTGRES_PASSWORD, GCS_JWT_SECRET, GCS_ADMIN_PASSWORD
```

## 2. Build aplikasi web
```bash
cd app && npm ci
NEXT_PUBLIC_API_URL=http://<LAN_IP>:8081/api npm run build   # hasil di app/out, disajikan Caddy
```
Tanpa `NEXT_PUBLIC_API_URL` aplikasi berjalan dalam mode simulasi (tanpa server).
Untuk Tauri desktop, gunakan URL API yang sama saat build.

## 3. Jalankan
```bash
cd infra && docker compose up -d --build
pm2 start pm2/ecosystem.config.cjs && pm2 save && pm2 startup
```
Konsol: `http://<LAN_IP>:8081`. Login pertama: `admin` / `GCS_ADMIN_PASSWORD` (ganti di Pengaturan).

## 4. Arahkan perangkat
| Perangkat | URL |
|---|---|
| Bridge DJI M4T (telemetri) | `ws://<LAN_IP>:8080/telemetry/m4t-001` |
| Bridge DJI M4T (video) | `rtmp://<LAN_IP>:1935/m4t` |
| Bridge Autel EVO II | `ws://<LAN_IP>:8080/ws/drone` |
| LITO X1 / SIYI / HP CCTV | `rtmp://<LAN_IP>:1935/live/<nama>` |

Daftarkan drone (ID sama dengan bridge) dan sumber video dengan URL RTMP yang sama; HP/CCTV
didaftarkan di halaman **Kamera**. Lihat `docs/bridge-protocol.md`.

## Catatan
- **WebRTC** butuh UDP 8189 ke server: lancar di LAN/VPN (WireGuard/Tailscale). Cloudflare Tunnel hanya
  meneruskan HTTP (konsol, API, WebSocket) — video live jarak jauh sebaiknya lewat VPN.
- Server Linux + NVIDIA: `docker compose --profile gpu up -d` (worker CUDA + Ollama di container).
- Model CoreML (`.mlpackage`) hanya berjalan di worker macOS; di Linux gunakan `.pt`/`.onnx`/`.engine`.
- Backup database: `docker compose exec postgres pg_dump -U gcs gcs > backup.sql`.
