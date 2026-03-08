@echo off
REM Sandboxie Installer Build Script
REM Build installer package using NSIS

echo ========================================
echo Sandboxie Installer Build Script
echo ========================================
echo.

REM Check if NSIS is installed
where makensis >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] NSIS compiler not found
    echo Please install NSIS from: https://nsis.sourceforge.io/Download
    echo Or add NSIS directory to PATH
    pause
    exit /b 1
)

REM Check build output directory
if not exist "..\Bin\x64\SbieRelease\SbieDrv.sys" (
    echo [ERROR] Build output files not found
    echo Please build x64 Release version first
    echo Path: ..\Bin\x64\SbieRelease\
    pause
    exit /b 1
)

echo [INFO] NSIS compiler found
echo [INFO] Build output files found
echo.

REM Build installer
echo [START] Building NSIS installer...
echo.

makensis /V3 SandboxieSimple.nsi

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo [SUCCESS] Installer build completed!
    echo ========================================
    echo.
    echo Output: ..\Bin\x64\SandboxieInstall-5.72.3-x64.exe
    echo.
) else (
    echo.
    echo ========================================
    echo [FAILED] Installer build failed!
    echo ========================================
    echo.
)

pause
