// Native processes on the macOS host (Apple Silicon): the inference worker needs
// CoreML / Metal, which Docker Desktop cannot expose.
//   pm2 start infra/pm2/ecosystem.config.cjs && pm2 save
const path = require("node:path");

const root = path.resolve(__dirname, "..", "..");
const python = path.join(root, "backend", ".venv", "bin", "python");

module.exports = {
  apps: [
    {
      name: "gcs-worker",
      cwd: path.join(root, "backend"),
      script: python,
      args: "-m gcs_worker",
      interpreter: "none",
      autorestart: true,
      max_restarts: 50,
      restart_delay: 3000,
      env: {
        GCS_WORKER_NATS_URL: "nats://localhost:4222",
        GCS_WORKER_MODELS_DIR: path.join(root, "infra", "data", "models"),
        GCS_WORKER_OLLAMA_URL: "http://localhost:11434",
        GCS_WORKER_PROMPTS_FILE: path.join(root, "infra", "worker", "prompts.toml"),
        GCS_WORKER_ENCODER: "h264_videotoolbox",
        GCS_WORKER_DETECTOR_BACKEND: "auto",
      },
    },
  ],
};
