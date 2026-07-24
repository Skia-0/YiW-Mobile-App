@echo off
echo ========================================
echo   YiW Mobile App - Quick Pull
echo ========================================
echo.

cd /d "%~dp0"

echo Pulling latest changes...
git reset --hard origin/main

echo.
echo Done! Latest code is now on your machine.
echo.
pause
