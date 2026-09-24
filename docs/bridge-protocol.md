# Protokol Bridge Drone

Bridge (aplikasi di HP/RC yang terhubung ke drone) **membuka koneksi WebSocket ke server GCS**.
Server tidak pernah menghubungi bridge. Satu koneksi = satu drone.

| Endpoint | Untuk | ID drone diambil dari |
|---|---|---|
| `ws://<server>:8080/telemetry/<droneId>` | Bridge DJI (format lama, M4T) | path |
| `ws://<server>:8080/telemetry?drone=<droneId>` | Bridge DJI | query, default `GCS_DJI_DEFAULT_DRONE_ID` |
| `ws://<server>:8080/ws/drone` | Bridge Autel / generik | field `droneId` di tiap pesan |
| `ws://<server>:8080/bridge/<droneId>` | Bridge generik, ID tetap | path |

Jika `GCS_BRIDGE_TOKEN` diisi, tambahkan `?token=<token>` di URL (tanpa token → ditutup kode 4401).
Drone harus sudah terdaftar di halaman **Drone** dengan ID yang sama; data dari ID tak dikenal diabaikan
dan dicatat sekali di log kejadian.

## 1. Format yang sudah didukung (tanpa perubahan di bridge)

### DJI Matrice 4T (MSDK v5) — 10 Hz
Bridge v2 menambah `mode`, `motors`, `home{lat,lon}` dan mengirim `hello`, `ack`, `event` di koneksi yang sama.
```json
{"pos":{"lat":-6.2,"lon":106.84,"alt":42.1},"att":{"pitch":-2.1,"roll":0.4,"yaw":-91.0},
 "vel":{"x":4.2,"y":-0.3,"z":-0.5},"heading":-91.0,"flying":true,"sats":19,"battery":78,"ts":1790000000000}
```
- `heading`/`yaw` −180..180 → dinormalisasi 0..360. `vel.z` positif = turun (NED).
- `flying` → fase terbang; home diambil dari posisi terakhir sebelum lepas landas.
- Server → bridge (kapabilitas `lens`): `{"cmd":"set_lens","lens":"rgb"|"thermal"}`,
  `{"cmd":"set_display","mode":"split"|"single"}`.
- Video: RTMP ke `rtmp://<server>:1935/<path>` (mis. `/m4t`), daftarkan URL yang sama di sumber video drone.

### Autel EVO II V3 — 5 Hz
```json
{"type":"telemetry","droneId":"evo2-v3-001","timestamp":1790000000000,
 "data":{"connected":true,"latitude":-6.21,"longitude":106.85,"relativeAltitude":42.0,"altitudeMsl":50.1,
         "roll":2.0,"pitch":-4.0,"yaw":181.0,"heading":181.0,"groundSpeed":7.5,"velocityZ":-0.5,
         "satelliteCount":16,"gpsFixType":3,"batteryPercentage":64,"batteryVoltage":15.2,
         "homeLatitude":-6.2,"homeLongitude":106.84,"distanceToHome":1200,"flightMode":"GPS_FLIGHT",
         "rcSignalLost":false,"goHomePending":false,"gimbalPitch":-30.0}}
```
- `flightMode` Autel dipetakan ke mode GCS (GPS_FLIGHT→POSHOLD, NORMAL_GO_HOME→RTL, LANDING→LAND, …).
- Unit sudut diatur `GCS_AUTEL_ATTITUDE_UNIT=deg|rad`.
- `connected:false` → posisi diabaikan dan kejadian "pesawat terputus dari RC" dicatat.

## 2. Kapabilitas (opsional, disarankan untuk bridge baru)

Pesan pertama setelah terhubung:
```json
{"type":"hello","droneId":"x","vendor":"autel","capabilities":["telemetry","commands","mission"]}
```
Tanpa `hello`: DJI = `telemetry,lens`, lainnya = `telemetry`. GCS menonaktifkan tombol yang tidak
didukung (tooltip "Bridge read-only …") dan server menolak perintah dengan pesan yang sama.

## 3. Perintah & misi (diimplementasikan di bridge DJI dan Autel v2)

Server → bridge:
```json
{"type":"command","id":"c-8f2a","command":{"type":"takeoff","altM":30}}
{"type":"mission","id":"m-11b0","plan":{"name":"…","takeoffAltM":30,"endAction":"rtl","waypoints":[…]}}
```
Bridge → server (wajib, dalam 10 s untuk perintah / 30 s untuk misi; dicocokkan lewat `id`):
```json
{"type":"ack","id":"c-8f2a","accepted":true,"message":"Lepas landas ke 30 m"}
```
Daftar `command.type`: `arm`, `disarm`, `takeoff{altM}`, `land`, `rtl`, `hold`, `set-mode{mode}`,
`goto{lat,lon,altM}`, `mission-start`, `mission-pause`, `payload-release`, `set-lens{lens}`.
Semua perintah (diterima atau ditolak) tercatat di tabel audit `command_log`.

## 4. Drone demo

Drone dengan saklar **Drone demo** disimulasikan di server (tidak butuh bridge), punya semua
kapabilitas, dan tampil ungu dengan label DEMO. Eksekusi titik drop hanya berjalan di drone demo;
lokasi target drop untuk drone nyata tetap tersimpan dan tampil di peta.

Kapabilitas `commands`/`mission` diumumkan hanya bila saklar **Izinkan kendali dari GCS** di aplikasi bridge menyala. Panduan lengkap: `docs/manual/manual.pdf`.
