$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
if (-not (Test-Path '.env')) { Copy-Item '.env.example' '.env' }
if (-not (Test-Path 'backend/.venv')) { python -m venv backend/.venv }
& "$root/backend/.venv/Scripts/python.exe" -m pip install -e "$root/backend"
Start-Process -WindowStyle Hidden -FilePath "$root/backend/.venv/Scripts/python.exe" -ArgumentList '-m','app.seed'
Start-Process -WindowStyle Hidden -FilePath "$root/backend/.venv/Scripts/python.exe" -ArgumentList '-m','uvicorn','app.main:app','--host','0.0.0.0','--port','8000' -WorkingDirectory "$root/backend"
Start-Process -WindowStyle Hidden -FilePath "$root/backend/.venv/Scripts/python.exe" -ArgumentList '-m','app.worker' -WorkingDirectory "$root/backend"
Set-Location "$root/frontend"
npm install
npm run dev
