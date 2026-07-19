#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/wanderlust-backend"
FLUTTER_DIR="$ROOT_DIR/wanderlust-frontend-flutter"

BACKEND_HOST="${BACKEND_HOST:-}"
BACKEND_PORT="${BACKEND_PORT:-}"
BACKEND_URL="${BACKEND_BASE_URL:-}"
CALL_SERVICE_URL="${CALL_SERVICE_BASE_URL:-}"
PYTHON_BIN="${PYTHON_BIN:-}"
FLUTTER_DEVICE="${FLUTTER_DEVICE:-}"
FLUTTER_SIM="${FLUTTER_SIM:-iPhone 17 Pro}"
SKIP_BACKEND_INSTALL="${SKIP_BACKEND_INSTALL:-0}"
SKIP_FLUTTER_PUB_GET="${SKIP_FLUTTER_PUB_GET:-0}"

BACKEND_PID=""

log() {
  printf '\n[%s] %s\n' "wanderlust" "$*"
}

die() {
  printf '\n[start.sh] %s\n' "$*" >&2
  exit 1
}

is_local_url() {
  case "$1" in
    http://127.0.0.1:*|http://localhost:*|http://0.0.0.0:*) return 0 ;;
    *) return 1 ;;
  esac
}

cleanup() {
  if [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" 2>/dev/null; then
    log "Stopping local backend..."
    kill "$BACKEND_PID" 2>/dev/null || true
    wait "$BACKEND_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT
trap 'exit 130' INT TERM

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

choose_python() {
  if [[ -n "$PYTHON_BIN" ]]; then
    command -v "$PYTHON_BIN" >/dev/null 2>&1 || die "PYTHON_BIN is set to '$PYTHON_BIN' but it was not found."
    return
  fi

  if command -v python3.11 >/dev/null 2>&1; then
    PYTHON_BIN="python3.11"
  elif command -v python3 >/dev/null 2>&1; then
    PYTHON_BIN="python3"
  else
    die "Python 3.11 or python3 is required for the backend."
  fi
}

env_value() {
  local key="$1"
  local env_file="$BACKEND_DIR/.env"

  [[ -f "$env_file" ]] || return 0
  "$PYTHON_BIN" - "$env_file" "$key" <<'PY'
import pathlib
import sys

env_path = pathlib.Path(sys.argv[1])
target = sys.argv[2]

for raw_line in env_path.read_text().splitlines():
    line = raw_line.strip()
    if not line or line.startswith("#") or "=" not in line:
        continue
    key, value = line.split("=", 1)
    if key.strip() != target:
        continue
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        value = value[1:-1]
    print(value)
    break
PY
}

configure_local_urls() {
  local env_backend_host env_backend_port env_backend_url env_call_service_url env_public_backend_url
  env_backend_host="$(env_value BACKEND_HOST || true)"
  env_backend_port="$(env_value BACKEND_PORT || true)"
  env_backend_url="$(env_value BACKEND_BASE_URL || true)"
  env_call_service_url="$(env_value CALL_SERVICE_BASE_URL || true)"
  env_public_backend_url="$(env_value PUBLIC_BACKEND_BASE_URL || true)"

  BACKEND_HOST="${BACKEND_HOST:-${env_backend_host:-127.0.0.1}}"
  BACKEND_PORT="${BACKEND_PORT:-${env_backend_port:-8000}}"
  BACKEND_URL="${BACKEND_URL:-${env_public_backend_url:-${env_backend_url:-http://127.0.0.1:${BACKEND_PORT}}}}"
  CALL_SERVICE_URL="${CALL_SERVICE_URL:-${env_call_service_url:-${env_public_backend_url:-$BACKEND_URL}}}"
}

wait_for_backend() {
  log "Waiting for backend at ${BACKEND_URL}/readyz..."
  for _ in $(seq 1 45); do
    if curl -fsS "${BACKEND_URL}/readyz" >/dev/null 2>&1; then
      log "Backend ready at ${BACKEND_URL}"
      return
    fi
    if [[ -n "$BACKEND_PID" ]] && ! kill -0 "$BACKEND_PID" 2>/dev/null; then
      die "Backend process exited before becoming ready."
    fi
    sleep 1
  done
  die "Backend did not become ready at ${BACKEND_URL}/readyz."
}

stop_process_on_port() {
  local port="$1"
  local pids
  pids="$(lsof -tiTCP:"$port" -sTCP:LISTEN 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    log "Stopping existing local process on port ${port}..."
    # shellcheck disable=SC2086
    kill $pids 2>/dev/null || true
    sleep 1
  fi
}

setup_backend() {
  log "Setting up local backend..."
  [[ -d "$BACKEND_DIR" ]] || die "Backend directory not found: $BACKEND_DIR"
  [[ -f "$BACKEND_DIR/.env" ]] || log "wanderlust-backend/.env not found. The backend can start, but real Gemini/Maps/Twilio calls need local env values."

  cd "$BACKEND_DIR"
  if [[ ! -d .venv ]]; then
    log "Creating backend virtual environment with ${PYTHON_BIN}..."
    "$PYTHON_BIN" -m venv .venv
  fi

  # shellcheck source=/dev/null
  source .venv/bin/activate

  if [[ "$SKIP_BACKEND_INSTALL" != "1" ]]; then
    log "Installing backend dependencies..."
    python -m pip install -q --upgrade pip
    python -m pip install -q -e ".[dev]"
  fi

  local google_api_key maps_backend_key
  google_api_key="$(env_value GOOGLE_API_KEY || true)"
  maps_backend_key="$(env_value GOOGLE_MAPS_BACKEND_API_KEY || true)"
  if [[ -z "$google_api_key" || -z "$maps_backend_key" ]]; then
    log "Some backend API keys are missing in wanderlust-backend/.env. Local UI still runs; real itinerary generation needs GOOGLE_API_KEY and GOOGLE_MAPS_BACKEND_API_KEY."
  fi

  stop_process_on_port "$BACKEND_PORT"

  log "Starting local FastAPI backend on ${BACKEND_URL}..."
  BACKEND_HOST="$BACKEND_HOST" BACKEND_PORT="$BACKEND_PORT" \
    python -m uvicorn app.main:app --reload --host "$BACKEND_HOST" --port "$BACKEND_PORT" &
  BACKEND_PID=$!
  wait_for_backend
}

boot_ios_simulator_if_needed() {
  command -v xcrun >/dev/null 2>&1 || return 0
  command -v open >/dev/null 2>&1 || return 0

  if [[ -n "$FLUTTER_DEVICE" && "$FLUTTER_DEVICE" != "$FLUTTER_SIM" ]]; then
    return 0
  fi

  local sim_udid
  sim_udid="$(xcrun simctl list devices booted 2>/dev/null | grep -E "$FLUTTER_SIM \\([A-F0-9-]+\\)" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' || true)"
  if [[ -z "$sim_udid" ]]; then
    sim_udid="$(xcrun simctl list devices available 2>/dev/null | grep -E "$FLUTTER_SIM \\([A-F0-9-]+\\)" | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/' || true)"
  fi

  if [[ -z "$sim_udid" ]]; then
    log "$FLUTTER_SIM not found. Set FLUTTER_DEVICE to an available device ID, or set FLUTTER_SIM to an installed simulator name."
    return 0
  fi

  if ! xcrun simctl list devices booted 2>/dev/null | grep -q "$sim_udid"; then
    log "Booting iOS simulator: $FLUTTER_SIM"
    xcrun simctl boot "$sim_udid" >/dev/null 2>&1 || true
  fi
  open -a Simulator >/dev/null 2>&1 || true
}

select_flutter_device() {
  if [[ -n "$FLUTTER_DEVICE" ]]; then
    return
  fi

  FLUTTER_DEVICE="$(flutter devices --machine 2>/dev/null | "$PYTHON_BIN" -c '
import json
import sys

try:
    devices = json.load(sys.stdin)
except Exception:
    devices = []

preferred_platforms = ("ios", "android", "darwin", "web-javascript")
for platform in preferred_platforms:
    for device in devices:
        if device.get("platform") == platform:
            print(device.get("id", ""))
            raise SystemExit
' || true)"

  [[ -n "$FLUTTER_DEVICE" ]] || die "No Flutter device found. Start a simulator/emulator, connect a device, or set FLUTTER_DEVICE."
}

setup_flutter() {
  log "Setting up Flutter frontend..."
  [[ -d "$FLUTTER_DIR" ]] || die "Flutter directory not found: $FLUTTER_DIR"

  cd "$FLUTTER_DIR"
  if [[ "$SKIP_FLUTTER_PUB_GET" != "1" ]]; then
    flutter pub get
  fi

  local maps_ios_key
  maps_ios_key="$(env_value GOOGLE_MAPS_IOS_API_KEY || true)"

  boot_ios_simulator_if_needed
  select_flutter_device

  local flutter_args=(
    run
    -d "$FLUTTER_DEVICE"
    --dart-define "PUBLIC_BACKEND_BASE_URL=$BACKEND_URL"
    --dart-define "BACKEND_BASE_URL=$BACKEND_URL"
  )

  if [[ -n "$CALL_SERVICE_URL" ]]; then
    flutter_args+=(--dart-define "CALL_SERVICE_BASE_URL=$CALL_SERVICE_URL")
    log "Cloud call-service URL configured for booking-call start/status requests."
  else
    log "CALL_SERVICE_BASE_URL/PUBLIC_BACKEND_BASE_URL is empty. Booking calls will use BACKEND_BASE_URL."
  fi

  if [[ -n "$maps_ios_key" ]]; then
    export GOOGLE_MAPS_IOS_API_KEY="$maps_ios_key"
    flutter_args+=(--dart-define "GOOGLE_MAPS_IOS_API_KEY=$maps_ios_key")
  else
    log "GOOGLE_MAPS_IOS_API_KEY is missing in wanderlust-backend/.env. Map rendering on iOS may be unavailable."
  fi

  log "Starting Flutter app on ${FLUTTER_DEVICE}"
  log "Hot reload is available here: press r to hot reload, R to hot restart, q to quit."
  flutter "${flutter_args[@]}" "$@"
}

main() {
  require_command curl
  require_command lsof
  require_command flutter
  choose_python
  configure_local_urls

  if is_local_url "$BACKEND_URL"; then
    log "Local backend mode. This script does not run Cloud Run, Terraform, gcloud, or deployment commands."
    setup_backend
  else
    log "Cloud backend mode. Using ${BACKEND_URL}; local FastAPI backend will not be started."
    wait_for_backend
  fi
  setup_flutter "$@"
}

main "$@"
