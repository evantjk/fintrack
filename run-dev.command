#!/bin/bash
#
# run-dev.command — macOS one-click setup + run for FinTrack.
#
# Double-click this file in Finder (or run it in Terminal). It will:
#   1. Check that python3 and flutter are installed.
#   2. Set up the API: create .venv, install requirements, make .env.
#   3. Set up the mobile app: flutter pub get.
#   4. Start fintrack-api (uvicorn) on :8000 in the background.
#   5. Start fintrack-mobile (Flutter web) on :5173 in Chrome (foreground).
#
# Closing this window (or pressing q in it) stops both servers.
#
# This is the macOS equivalent of run-dev.bat (which is Windows-only).

set -euo pipefail

# Resolve the folder this script lives in, so it works no matter where it's run from.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API="$ROOT/fintrack-api"
MOBILE="$ROOT/fintrack-mobile"

say()  { printf '\n\033[1;34m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[1;33m[!] %s\033[0m\n' "$1"; }
die()  { printf '\033[1;31m[x] %s\033[0m\n' "$1"; exit 1; }

# --- 1. Prerequisites -------------------------------------------------------
say "Checking prerequisites"
command -v python3 >/dev/null 2>&1 || die "python3 not found. Install it (e.g. 'brew install python' or Xcode Command Line Tools)."
command -v flutter  >/dev/null 2>&1 || die "flutter not found in PATH. Install Flutter and add it to your PATH: https://docs.flutter.dev/get-started/install/macos"
echo "python3: $(python3 --version)"
echo "flutter: $(flutter --version | head -1)"

# Make sure the ports are free (these were a common gotcha).
port_busy() { lsof -nP -iTCP:"$1" -sTCP:LISTEN >/dev/null 2>&1; }
port_busy 8000 && die "Port 8000 is already in use. Stop whatever is using it, then try again."
port_busy 5173 && die "Port 5173 is already in use. Stop whatever is using it, then try again."

# --- 2. API setup -----------------------------------------------------------
say "Setting up fintrack-api"
cd "$API"
if [ ! -d .venv ]; then
  echo "Creating virtual environment (.venv)…"
  python3 -m venv .venv
fi
echo "Installing Python dependencies…"
.venv/bin/pip install --quiet --upgrade pip
.venv/bin/pip install --quiet -r requirements.txt

[ -f .env ] || { cp .env.example .env; echo "Created .env from .env.example"; }

if [ ! -f serviceAccountKey.json ]; then
  warn "serviceAccountKey.json is MISSING in fintrack-api/."
  warn "The app will load and you can see the UI, but login and data won't work without it."
  warn "Get it from: Firebase Console > Project settings > Service accounts > Generate new private key,"
  warn "then save it as: $API/serviceAccountKey.json"
  printf '\nContinue anyway? [y/N] '
  read -r ans
  case "$ans" in [yY]*) ;; *) die "Stopped. Add the key and run again." ;; esac
fi

# --- 3. Mobile setup --------------------------------------------------------
say "Setting up fintrack-mobile"
cd "$MOBILE"
flutter pub get

# --- 4. Start the API in the background -------------------------------------
say "Starting API on http://localhost:8000"
cd "$API"
.venv/bin/uvicorn app.main:app --reload --port 8000 > /tmp/fintrack-api.log 2>&1 &
API_PID=$!
# When this script exits (window closed / Ctrl+C / q), stop the API too.
trap 'echo; echo "Stopping API…"; kill $API_PID 2>/dev/null || true' EXIT

# Give it a moment and confirm it came up.
sleep 3
if curl -s -m 5 http://localhost:8000/health >/dev/null 2>&1; then
  echo "API is up (logs: /tmp/fintrack-api.log)"
else
  warn "API didn't respond yet — check /tmp/fintrack-api.log if the app can't reach it."
fi

# --- 5. Start the mobile app (foreground; this is where hot reload lives) ----
say "Starting Flutter web on http://localhost:5173 (Chrome will open)"
echo "Press 'r' to hot reload, 'R' to hot restart, 'q' to quit."
cd "$MOBILE"
flutter run -d chrome --web-port=5173

# (flutter run blocks until you quit; the EXIT trap then stops the API.)
