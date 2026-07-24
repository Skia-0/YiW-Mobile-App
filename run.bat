@echo off
echo ========================================
echo   YiW Mobile App - Pull and Run
echo ========================================
echo.

cd /d "%~dp0"

echo Step 1: Pulling latest changes...
git reset --hard origin/main
echo.

echo Step 2: Installing dependencies...
flutter pub get
echo.

echo Step 3: Launching app...
flutter run -d R5CY811JM8B

pause
