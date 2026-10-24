@echo off
title ENSTP Campus Navigator
cd /d "%~dp0"
echo Starting ENSTP Campus Navigator at http://127.0.0.1:8000/
echo Keep this window open while using the website.
python -m http.server 8000
if errorlevel 1 (
  echo.
  echo Could not start the server. Check that Python is installed and available as "python".
  pause
)
