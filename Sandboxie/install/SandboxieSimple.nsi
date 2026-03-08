;----------------------------------------------------------------------------
; Sandboxie 简化安装脚本
; 用于打包已编译的 x64 版本
;----------------------------------------------------------------------------

SetCompressor /SOLID /FINAL lzma

!include "MUI2.nsh"
!include "x64.nsh"

;----------------------------------------------------------------------------
; 版本信息
;----------------------------------------------------------------------------

!define VERSION "5.72.3"
!define PRODUCT_NAME "Sandboxie"
!define PRODUCT_FULL_NAME "Sandboxie"
!define COMPANY_NAME "Sandboxie-Plus.com"
!define COPYRIGHT_STRING "Copyright © 2020-2026 by David Xanatos"

;----------------------------------------------------------------------------
; 安装配置
;----------------------------------------------------------------------------

Name "${PRODUCT_FULL_NAME} ${VERSION} (64-bit)"
OutFile "..\Bin\x64\SandboxieInstall-${VERSION}-x64.exe"
InstallDir "$PROGRAMFILES\${PRODUCT_FULL_NAME}"

; 请求管理员权限
RequestExecutionLevel admin

; 显示安装详情
ShowInstDetails show
ShowUnInstDetails show

;----------------------------------------------------------------------------
; 版本信息
;----------------------------------------------------------------------------

VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${PRODUCT_FULL_NAME}"
VIAddVersionKey "CompanyName" "${COMPANY_NAME}"
VIAddVersionKey "LegalCopyright" "${COPYRIGHT_STRING}"
VIAddVersionKey "FileDescription" "${PRODUCT_NAME} Installer"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "ProductVersion" "${VERSION}"

;----------------------------------------------------------------------------
; 界面配置
;----------------------------------------------------------------------------

!define MUI_ICON "..\apps\res\sandbox-full.ico"
!define MUI_UNICON "..\apps\res\sandbox-full.ico"

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

;----------------------------------------------------------------------------
; 安装页面
;----------------------------------------------------------------------------

!insertmacro MUI_PAGE_LICENSE "LICENSE.TXT"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

;----------------------------------------------------------------------------
; 卸载页面
;----------------------------------------------------------------------------

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;----------------------------------------------------------------------------
; 语言
;----------------------------------------------------------------------------

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "SimpChinese"

;----------------------------------------------------------------------------
; 安装节
;----------------------------------------------------------------------------

Section "MainSection" SEC01

    SetOutPath "$INSTDIR"
    SetOverwrite on
    
    ; 核心文件
    File "..\Bin\x64\SbieRelease\SbieDrv.sys"
    File "..\Bin\x64\SbieRelease\SbieDll.dll"
    File "..\Bin\x64\SbieRelease\SbieSvc.exe"
    File "..\Bin\x64\SbieRelease\SbieMsg.dll"
    File "..\Bin\x64\SbieRelease\SbieCtrl.exe"
    File "..\Bin\x64\SbieRelease\SbieCtrl.exe.manifest"
    File "..\Bin\x64\SbieRelease\Start.exe"
    File "..\Bin\x64\SbieRelease\SbieIni.exe"
    File "..\Bin\x64\SbieRelease\KmdUtil.exe"
    File "..\Bin\x64\SbieRelease\SboxHostDll.dll"
    
    ; COM 服务
    File "..\Bin\x64\SbieRelease\SandboxieRpcSs.exe"
    File "..\Bin\x64\SbieRelease\SandboxieDcomLaunch.exe"
    File "..\Bin\x64\SbieRelease\SandboxieBITS.exe"
    File "..\Bin\x64\SbieRelease\SandboxieCrypto.exe"
    File "..\Bin\x64\SbieRelease\SandboxieWUAU.exe"
    
    ; 配置和文档
    File "Templates.ini"
    File "LICENSE.TXT"
    File "whatsnew.html"
    File "Manifest0.txt"
    File "Manifest1.txt"
    File "Manifest2.txt"
    
    ; 创建快捷方式
    CreateShortCut "$INSTDIR\QuickLaunch.lnk" "$INSTDIR\Start.exe" "default_browser"
    
    ; 写入注册表
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayName" "${PRODUCT_FULL_NAME} ${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayIcon" "$INSTDIR\Start.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "Publisher" "${COMPANY_NAME}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "InstallLocation" "$INSTDIR"
    
    ; 创建卸载程序
    WriteUninstaller "$INSTDIR\Uninstall.exe"
    
    ; 安装驱动和服务
    DetailPrint "正在安装驱动和服务..."
    
    ; 停止现有服务（如果存在）
    nsExec::ExecToLog 'sc stop SbieSvc'
    nsExec::ExecToLog 'sc stop SbieDrv'
    Sleep 1000
    
    ; 安装驱动
    nsExec::ExecToLog '"$INSTDIR\KmdUtil.exe" install SbieDrv "$INSTDIR\SbieDrv.sys" type=kernel start=demand altitude=86900'
    Pop $0
    DetailPrint "驱动安装返回值: $0"
    
    ; 安装服务
    nsExec::ExecToLog '"$INSTDIR\KmdUtil.exe" install SbieSvc "$INSTDIR\SbieSvc.exe" type=own start=auto "display=Sandboxie Service"'
    Pop $0
    DetailPrint "服务安装返回值: $0"
    
    ; 启动服务
    Sleep 1000
    nsExec::ExecToLog 'sc start SbieSvc'
    Pop $0
    DetailPrint "服务启动返回值: $0"
    
    ; 创建开始菜单快捷方式
    SetShellVarContext all
    CreateDirectory "$SMPROGRAMS\${PRODUCT_FULL_NAME}"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_FULL_NAME}\Sandboxie Control.lnk" "$INSTDIR\SbieCtrl.exe" "/open"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_FULL_NAME}\Run Sandboxed.lnk" "$INSTDIR\Start.exe" "/box:__ask__ run_dialog"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_FULL_NAME}\Run Web Browser.lnk" "$INSTDIR\Start.exe" "default_browser"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_FULL_NAME}\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
    
SectionEnd

;----------------------------------------------------------------------------
; 卸载节
;----------------------------------------------------------------------------

Section "Uninstall"

    ; 停止服务
    DetailPrint "正在停止服务..."
    nsExec::ExecToLog 'sc stop SbieSvc'
    nsExec::ExecToLog 'sc stop SbieDrv'
    Sleep 2000
    
    ; 删除服务
    DetailPrint "正在删除服务..."
    nsExec::ExecToLog '"$INSTDIR\KmdUtil.exe" delete SbieSvc'
    nsExec::ExecToLog '"$INSTDIR\KmdUtil.exe" delete SbieDrv'
    
    ; 删除文件
    Delete "$INSTDIR\SbieDrv.sys"
    Delete "$INSTDIR\SbieDll.dll"
    Delete "$INSTDIR\SbieSvc.exe"
    Delete "$INSTDIR\SbieMsg.dll"
    Delete "$INSTDIR\SbieCtrl.exe"
    Delete "$INSTDIR\SbieCtrl.exe.manifest"
    Delete "$INSTDIR\Start.exe"
    Delete "$INSTDIR\SbieIni.exe"
    Delete "$INSTDIR\KmdUtil.exe"
    Delete "$INSTDIR\SboxHostDll.dll"
    Delete "$INSTDIR\SandboxieRpcSs.exe"
    Delete "$INSTDIR\SandboxieDcomLaunch.exe"
    Delete "$INSTDIR\SandboxieBITS.exe"
    Delete "$INSTDIR\SandboxieCrypto.exe"
    Delete "$INSTDIR\SandboxieWUAU.exe"
    Delete "$INSTDIR\Templates.ini"
    Delete "$INSTDIR\LICENSE.TXT"
    Delete "$INSTDIR\whatsnew.html"
    Delete "$INSTDIR\Manifest0.txt"
    Delete "$INSTDIR\Manifest1.txt"
    Delete "$INSTDIR\Manifest2.txt"
    Delete "$INSTDIR\QuickLaunch.lnk"
    Delete "$INSTDIR\Uninstall.exe"
    
    ; 删除目录
    RMDir "$INSTDIR"
    
    ; 删除开始菜单
    SetShellVarContext all
    RMDir /r "$SMPROGRAMS\${PRODUCT_FULL_NAME}"
    
    ; 删除注册表
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
    
    ; 提示可能需要重启
    MessageBox MB_YESNO|MB_ICONQUESTION "卸载完成。某些文件可能需要重启后才能完全删除。是否现在重启？" IDNO +2
    Reboot
    
SectionEnd

;----------------------------------------------------------------------------
; 初始化函数
;----------------------------------------------------------------------------

Function .onInit

    ; 检查是否为 64 位系统
    ${IfNot} ${RunningX64}
        MessageBox MB_OK|MB_ICONSTOP "此安装程序仅支持 64 位 Windows 系统！"
        Abort
    ${EndIf}
    
    ; 检查管理员权限
    UserInfo::GetAccountType
    Pop $0
    ${If} $0 != "admin"
        MessageBox MB_OK|MB_ICONSTOP "需要管理员权限才能安装 Sandboxie！"
        Abort
    ${EndIf}
    
    ; 检查是否已安装
    ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}" "UninstallString"
    ${If} $0 != ""
        MessageBox MB_YESNO|MB_ICONQUESTION "检测到已安装 Sandboxie。是否先卸载旧版本？" IDYES +2
        Abort
        
        ; 执行卸载
        ExecWait '$0 _?=$INSTDIR'
        Delete $0
        RMDir $INSTDIR
    ${EndIf}
    
FunctionEnd

Function un.onInit

    MessageBox MB_YESNO|MB_ICONQUESTION "确定要卸载 ${PRODUCT_FULL_NAME} 吗？" IDYES +2
    Abort
    
FunctionEnd
