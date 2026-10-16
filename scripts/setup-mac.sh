#!/usr/bin/env bash
# One-time setup of the native inference worker on macOS (Apple Silicon).
set -euo pipefail
cd "$(dirname "$0")/.."

command -v brew >/dev/null || { echo "Install Homebrew first: https://brew.sh"; exit 1; }
brew list ffmpeg >/dev/null 2>&1 || brew install ffmpeg
brew list python@3.12 >/dev/null 2>&1 || brew install python@3.12
command -v ollama >/dev/null || brew install --cask ollama
command -v pm2 >/dev/null || npm install -g pm2

python3.12 -m venv be/.venv
be/.venv/bin/pip install --upgrade pip
be/.venv/bin/pip install -e "be[worker]"

ollama pull moondream
ollama pull llama3.2:3b   # caption / answer translation to Bahasa Indonesia

mkdir -p data/models
echo "Done. Next: cp .env.example .env, edit it, docker compose up -d --build, pm2 start pm2/ecosystem.config.cjs"
