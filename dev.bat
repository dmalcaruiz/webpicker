@echo off
echo Setting up development environment...

REM Move flutter.js out of the way to avoid PATH conflicts
if exist "flutter.js" (
    echo Moving flutter.js to avoid PATH conflicts during development...
    move "flutter.js" "flutter.js.deploy"
    echo flutter.js moved to flutter.js.deploy
) else (
    echo flutter.js already moved or doesn't exist
)

echo.
echo Development environment ready!
echo You can now use 'flutter' commands without PATH conflicts.
echo.
echo To deploy later, run: deploy.bat
echo.
pause
