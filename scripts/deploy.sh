#!/usr/bin/env bash
# Update, build and (re)start PASUPASASTRA on this host.
#   scripts/deploy.sh            git pull, build the console and the images, start everything
#   scripts/deploy.sh --pull     use the CI images from GHCR instead of building them
#   scripts/deploy.sh --gpu      Linux + NVIDIA: worker and Ollama in Docker instead of PM2
#   scripts/deploy.sh --no-git   deploy the working tree as it is
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
[[ -f .env ]] || { echo "create .env from .env.example first"; exit 1; }

git_update=1
pull_images=0
profile=()
for arg in "$@"; do
  case "$arg" in
    --pull) pull_images=1 ;;
    --gpu) profile=(--profile gpu) ;;
    --no-git) git_update=0 ;;
    *) echo "usage: scripts/deploy.sh [--pull] [--gpu] [--no-git]"; exit 2 ;;
  esac
done

env_value() { grep -E "^$1=" .env | tail -n1 | cut -d= -f2- || true; }

if ((git_update)); then
  git pull --ff-only
  git submodule update --init --recursive
fi

port() { local v; v=$(env_value "$1"); echo "${v:-$2}"; }

# Refuse to start on a port another stack (NETRA, Molly, ...) already holds.
busy() { lsof -nP "-i$1:$2" ${3:+-sTCP:LISTEN} >/dev/null 2>&1; }
if [[ -z "$(docker compose ps -q 2>/dev/null)" ]]; then
  conflicts=()
  for spec in GCS_CONSOLE_PORT:8081:TCP GCS_API_PORT:8080:TCP GCS_RTMP_PORT:1935:TCP GCS_RTSP_PORT:8554:TCP \
              GCS_WEBRTC_PORT:8889:TCP GCS_HLS_PORT:8888:TCP GCS_DB_PORT:15432:TCP GCS_NATS_PORT:14222:TCP \
              GCS_WEBRTC_UDP_PORT:8189:UDP GCS_SRT_PORT:8890:UDP; do
    IFS=: read -r name def proto <<<"$spec"
    p=$(port "$name" "$def")
    if [[ $proto == TCP ]]; then busy TCP "$p" listen && conflicts+=("$name=$p"); else busy UDP "$p" && conflicts+=("$name=$p/udp"); fi
  done
  if ((${#conflicts[@]})); then
    echo "ports already in use: ${conflicts[*]}"
    echo "pick free ones in .env (see the Host ports block in .env.example)"
    exit 1
  fi
fi

lan_ip=$(env_value LAN_IP)
api_url=$(env_value CONSOLE_API_URL)
api_url=${api_url:-http://${lan_ip:?set LAN_IP in .env}:$(port GCS_CONSOLE_PORT 8081)/api}
echo "console -> $api_url"
(cd fe && npm ci --no-audit --no-fund && NEXT_PUBLIC_API_URL="$api_url" npm run build)

compose=(docker compose ${profile[@]+"${profile[@]}"})
if ((pull_images)); then
  "${compose[@]}" pull --ignore-pull-failures
  "${compose[@]}" up -d --remove-orphans
else
  "${compose[@]}" up -d --build --remove-orphans
fi

if [[ ${#profile[@]} -eq 0 ]] && command -v pm2 >/dev/null; then
  pm2 startOrReload pm2/ecosystem.config.cjs
  pm2 save
fi
"${compose[@]}" ps
