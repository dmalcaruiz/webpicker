@echo off
echo Copying Flutter web build files to repository root...

REM Temporarily move flutter.js to avoid PATH conflicts during development
if exist "flutter.js" (
    echo Moving flutter.js to avoid PATH conflicts...
    move "flutter.js" "flutter.js.deploy"
)

REM Copy all files from build/web to current directory
xcopy "build\web\*" "." /E /Y /I

echo.
echo Files copied successfully!
echo Now commit and push these changes to GitHub:
echo.
echo git add .
echo git commit -m "Deploy Flutter web app"
echo git push origin main
echo.
echo Your app will be available at: https://dmalcaruiz.github.io/webpicker/
echo.
pause
