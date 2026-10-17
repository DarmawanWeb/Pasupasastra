// Native processes on the macOS host (Apple Silicon): the inference worker needs
// CoreML / Metal, which Docker Desktop cannot expose.
//   pm2 start pm2/ecosystem.config.cjs && pm2 save
const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");

// Host ports come from the same .env as docker compose.
function env(name, fallback) {
  try {
    const line = fs.readFileSync(path.join(root, ".env"), "utf8").split("\n")
      .find((l) => l.startsWith(`${name}=`));
    const value = line?.slice(name.length + 1).trim();
    return value || fallback;
  } catch {
    return fallback;
  }
}
const python = path.join(root, "be", ".venv", "bin", "python");

module.exports = {
  apps: [
    {
      name: "gcs-worker",
      cwd: path.join(root, "be"),
      script: python,
      args: "-m gcs_worker",
      interpreter: "none",
      autorestart: true,
      max_restarts: 50,
      restart_delay: 3000,
      env: {
        GCS_WORKER_NATS_URL: `nats://localhost:${env("GCS_NATS_PORT", "14222")}`,
        GCS_WORKER_MODELS_DIR: path.join(root, "data", "models"),
        GCS_WORKER_OLLAMA_URL: "http://localhost:11434",
        GCS_WORKER_PROMPTS_FILE: path.join(root, "worker", "prompts.toml"),
        GCS_WORKER_ENCODER: "h264_videotoolbox",
        GCS_WORKER_DETECTOR_BACKEND: "auto",
      },
    },
  ],
};
