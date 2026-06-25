@echo off
REM Starts fintrack-api (FastAPI/uvicorn) and fintrack-mobile (Flutter, Chrome)
REM together for local development, each in its own window.
REM One-time setup (venv, dependencies, serviceAccountKey.json) is not done
REM here - see README.md.

set ROOT=%~dp0

start "fintrack-api (uvicorn :8000)" cmd /k "cd /d "%ROOT%fintrack-api" && .venv\Scripts\uvicorn.exe app.main:app --reload --port 8000"

start "fintrack-mobile (flutter/chrome)" cmd /k "cd /d "%ROOT%fintrack-mobile" && flutter run -d chrome --web-port=5173"
