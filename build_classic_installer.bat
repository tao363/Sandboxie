@echo off
REM 简化的 Sandboxie 经典版安装包生成脚本

set ARCH=x64
set SRC_PATH=%~dp0Sandboxie\Bin\%ARCH%\SbieRelease
set DEST_PATH=%~dp0Installer\Release\Sandboxie%ARCH%

echo 创建输出目录...
if not exist "%DEST_PATH%" mkdir "%DEST_PATH%"

echo 复制核心文件...
copy /y "%SRC_PATH%\SbieDrv.sys" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SbieDrv.pdb" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SbieSvc.exe" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SbieSvc.pdb" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SbieDll.dll" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SbieDll.pdb" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SbieCtrl.exe" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SbieCtrl.pdb" "%DEST_PATH%\"
copy /y "%SRC_PATH%\Start.exe" "%DEST_PATH%\"
copy /y "%SRC_PATH%\Start.pdb" "%DEST_PATH%\"
copy /y "%SRC_PATH%\kmdutil.exe" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SbieIni.exe" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SbieMsg.dll" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SboxHostDll.dll" "%DEST_PATH%\"

echo 复制 COM 服务...
copy /y "%SRC_PATH%\SandboxieBITS.exe" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SandboxieCrypto.exe" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SandboxieDcomLaunch.exe" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SandboxieRpcSs.exe" "%DEST_PATH%\"
copy /y "%SRC_PATH%\SandboxieWUAU.exe" "%DEST_PATH%\"

echo 复制 32 位组件...
if not exist "%DEST_PATH%\32" mkdir "%DEST_PATH%\32"
copy /y "%~dp0Sandboxie\Bin\Win32\SbieRelease\SbieDll.dll" "%DEST_PATH%\32\"
copy /y "%~dp0Sandboxie\Bin\Win32\SbieRelease\SbieDll.pdb" "%DEST_PATH%\32\"

echo 复制配置文件...
copy /y "%~dp0Sandboxie\install\Templates.ini" "%DEST_PATH%\"
copy /y "%~dp0Sandboxie\install\Manifest0.txt" "%DEST_PATH%\"
copy /y "%~dp0Sandboxie\install\Manifest1.txt" "%DEST_PATH%\"
copy /y "%~dp0Sandboxie\install\Manifest2.txt" "%DEST_PATH%\"

echo.
echo 文件复制完成！
echo 输出目录: %DEST_PATH%
echo.
echo 现在可以手动运行 Inno Setup 编译安装脚本，或者直接使用编译后的文件。
pause
