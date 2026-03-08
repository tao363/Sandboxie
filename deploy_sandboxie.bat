@echo off
REM Sandboxie 快速部署脚本
REM 将编译后的文件复制到 Sandboxie 安装目录

echo ========================================
echo Sandboxie 快速部署工具
echo ========================================
echo.

set "SRC_PATH=F:\Project\AI\sanbox\Sandboxie\Sandboxie\Bin\x64\SbieRelease"
set "DEST_PATH=C:\Program Files\Sandboxie-Plus"

echo 源路径: %SRC_PATH%
echo 目标路径: %DEST_PATH%
echo.

REM 检查源路径是否存在
if not exist "%SRC_PATH%" (
    echo 错误: 源路径不存在！
    echo 请确认编译已完成。
    pause
    exit /b 1
)

REM 检查目标路径
if not exist "%DEST_PATH%" (
    echo 警告: 目标路径不存在！
    echo 请先安装 Sandboxie-Plus 或手动创建目录。
    pause
    exit /b 1
)

echo 准备停止 Sandboxie 服务...
net stop SbieSvc 2>nul
sc stop SbieDrv 2>nul
timeout /t 2 /nobreak >nul

echo.
echo 正在复制文件...

REM 备份原文件
if exist "%DEST_PATH%\SbieDrv.sys" (
    echo 备份原文件...
    copy /y "%DEST_PATH%\SbieDrv.sys" "%DEST_PATH%\SbieDrv.sys.bak" >nul
    copy /y "%DEST_PATH%\SbieSvc.exe" "%DEST_PATH%\SbieSvc.exe.bak" >nul
    copy /y "%DEST_PATH%\SbieDll.dll" "%DEST_PATH%\SbieDll.dll.bak" >nul
)

REM 复制核心文件
echo 复制驱动和服务...
copy /y "%SRC_PATH%\SbieDrv.sys" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SbieDrv.pdb" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SbieSvc.exe" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SbieSvc.pdb" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SbieDll.dll" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SbieDll.pdb" "%DEST_PATH%\" >nul

echo 复制工具程序...
copy /y "%SRC_PATH%\SbieCtrl.exe" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\Start.exe" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\kmdutil.exe" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SbieIni.exe" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SbieMsg.dll" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SboxHostDll.dll" "%DEST_PATH%\" >nul

echo 复制 COM 服务...
copy /y "%SRC_PATH%\SandboxieBITS.exe" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SandboxieCrypto.exe" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SandboxieDcomLaunch.exe" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SandboxieRpcSs.exe" "%DEST_PATH%\" >nul
copy /y "%SRC_PATH%\SandboxieWUAU.exe" "%DEST_PATH%\" >nul

REM 复制 32 位 DLL（如果存在）
if exist "F:\Project\AI\sanbox\Sandboxie\Sandboxie\Bin\Win32\SbieRelease\SbieDll.dll" (
    echo 复制 32 位组件...
    if not exist "%DEST_PATH%\32" mkdir "%DEST_PATH%\32"
    copy /y "F:\Project\AI\sanbox\Sandboxie\Sandboxie\Bin\Win32\SbieRelease\SbieDll.dll" "%DEST_PATH%\32\" >nul
    copy /y "F:\Project\AI\sanbox\Sandboxie\Sandboxie\Bin\Win32\SbieRelease\SbieDll.pdb" "%DEST_PATH%\32\" >nul
)

echo.
echo ========================================
echo 部署完成！
echo ========================================
echo.
echo 现在启动 Sandboxie 服务...
sc start SbieDrv
net start SbieSvc

echo.
echo 完成！你可以启动 SandMan.exe 或 SbieCtrl.exe 使用 Sandboxie。
echo.
pause
