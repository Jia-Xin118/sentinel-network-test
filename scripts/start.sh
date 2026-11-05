#!/usr/bin/env sh
set -eu
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)"
cd "$ROOT"
[ -f .env ] || cp .env.example .env
python3 -m venv backend/.venv
backend/.venv/bin/pip install -e backend
backend/.venv/bin/python -m app.seed
(cd backend && ../backend/.venv/bin/uvicorn app.main:app --host 0.0.0.0 --port 8000) &
(cd backend && ../backend/.venv/bin/python -m app.worker) &
(cd frontend && npm install && npm run dev)
