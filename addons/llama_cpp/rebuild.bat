@echo off
echo ================================================
echo   Rebuilding GDExtension with Encoding Fix
echo ================================================
echo.

echo [1/3] Checking for Godot processes...
tasklist /FI "IMAGENAME eq Godot_v4.5.1-stable_win64.exe" 2>NUL | find /I /N "Godot_v4.5.1-stable_win64.exe">NUL
if "%ERRORLEVEL%"=="0" (
    echo.
    echo WARNING: Godot is still running!
    echo Please close Godot Editor completely before continuing.
    echo.
    pause
    exit /b 1
)

echo OK - No Godot process found
echo.

echo [2/3] Cleaning old DLL...
cd /d "%~dp0"
if exist "bin\libllama_godot.windows.template_debug.x86_64.dll" (
    del /F "bin\libllama_godot.windows.template_debug.x86_64.dll" 2>NUL
    if errorlevel 1 (
        echo ERROR: Cannot delete DLL. Please close any programs using it.
        pause
        exit /b 1
    )
    echo OK - Old DLL removed
) else (
    echo OK - No old DLL found
)
echo.

echo [3/3] Compiling GDExtension...
python -m SCons platform=windows target=template_debug
if errorlevel 1 (
    echo.
    echo ERROR: Compilation failed!
    pause
    exit /b 1
)

echo.
echo ================================================
echo   SUCCESS! DLL rebuilt successfully.
echo ================================================
echo.
echo Now you can:
echo 1. Open Godot Editor
echo 2. Run the test scene (F6)
echo 3. All logs should be in English now!
echo.
pause

