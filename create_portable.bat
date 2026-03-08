@echo off
REM 创建 Sandboxie 便携版

echo ========================================
echo Sandboxie 便携版打包工具
echo ========================================
echo.

set "SRC_PATH=F:\Project\AI\sanbox\Sandboxie\Sandboxie\Bin\x64\SbieRelease"
set "PORTABLE_PATH=F:\Project\AI\sanbox\Sandboxie\Sandboxie-Portable"

echo 源路径: %SRC_PATH%
echo 便携版路径: %PORTABLE_PATH%
echo.

REM 创建便携版目录
if not exist "%PORTABLE_PATH%" mkdir "%PORTABLE_PATH%"
if not exist "%PORTABLE_PATH%\32" mkdir "%PORTABLE_PATH%\32"

echo 正在复制文件...

REM 复制所有核心文件
xcopy /y /q "%SRC_PATH%\*.sys" "%PORTABLE_PATH%\"
xcopy /y /q "%SRC_PATH%\*.exe" "%PORTABLE_PATH%\"
xcopy /y /q "%SRC_PATH%\*.dll" "%PORTABLE_PATH%\"
xcopy /y /q "%SRC_PATH%\*.pdb" "%PORTABLE_PATH%\"

REM 复制 32 位组件
if exist "F:\Project\AI\sanbox\Sandboxie\Sandboxie\Bin\Win32\SbieRelease\SbieDll.dll" (
    echo 复制 32 位组件...
    copy /y "F:\Project\AI\sanbox\Sandboxie\Sandboxie\Bin\Win32\SbieRelease\SbieDll.dll" "%PORTABLE_PATH%\32\" >nul
    copy /y "F:\Project\AI\sanbox\Sandboxie\Sandboxie\Bin\Win32\SbieRelease\SbieDll.pdb" "%PORTABLE_PATH%\32\" >nul
)

REM 复制配置模板
echo 复制配置文件...
copy /y "F:\Project\AI\sanbox\Sandboxie\Sandboxie\install\Templates.ini" "%PORTABLE_PATH%\" >nul

REM 创建启动脚本
echo 创建启动脚本...
(
echo @echo off
echo echo 启动 Sandboxie 服务...
echo sc stop SbieDrv 2^>nul
echo sc delete SbieDrv 2^>nul
echo.
echo REM 加载驱动
echo kmdutil.exe install SbieDrv.sys
echo.
echo REM 启动服务
echo start SbieSvc.exe
echo.
echo echo Sandboxie 服务已启动！
echo echo 现在可以运行 SbieCtrl.exe 使用 Sandboxie。
echo pause
) > "%PORTABLE_PATH%\启动Sandboxie.bat"

REM 创建停止脚本
(
echo @echo off
echo echo 停止 Sandboxie 服务...
echo taskkill /f /im SbieSvc.exe 2^>nul
echo sc stop SbieDrv 2^>nul
echo sc delete SbieDrv 2^>nul
echo echo Sandboxie 已停止！
echo pause
) > "%PORTABLE_PATH%\停止Sandboxie.bat"

REM 创建说明文件
(
echo Sandboxie 便携版使用说明
echo ================================
echo.
echo 1. 以管理员身份运行 "启动Sandboxie.bat"
echo 2. 运行 SbieCtrl.exe 使用 Sandboxie
echo 3. 使用完毕后运行 "停止Sandboxie.bat"
echo.
echo 注意事项：
echo - 必须以管理员权限运行
echo - 需要启用测试签名模式（bcdedit /set testsigning on）
echo - 或者对驱动进行签名
echo.
echo 文件说明：
echo - SbieDrv.sys: 内核驱动
echo - SbieSvc.exe: 系统服务
echo - SbieDll.dll: 注入 DLL
echo - SbieCtrl.exe: 经典界面
echo - Start.exe: 启动工具
echo - kmdutil.exe: 驱动加载工具
echo.
) > "%PORTABLE_PATH%\使用说明.txt"

echo.
echo ========================================
echo 便携版创建完成！
echo ========================================
echo.
echo 输出目录: %PORTABLE_PATH%
echo.
echo 使用方法：
echo 1. 以管理员身份运行 "启动Sandboxie.bat"
echo 2. 运行 SbieCtrl.exe 使用 Sandboxie
echo.
pause
