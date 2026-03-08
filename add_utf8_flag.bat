@echo off
echo Adding /utf-8 flag to all vcxproj files...

cd /d "%~dp0"

for /r %%f in (*.vcxproj) do (
    echo Processing: %%f
    powershell -Command "(Get-Content '%%f') -replace '(<AdditionalOptions>(?!.*\/utf-8))', '<AdditionalOptions>/utf-8 ' | Set-Content '%%f'"
)

echo Done! Please reload the solution in Visual Studio.
pause
