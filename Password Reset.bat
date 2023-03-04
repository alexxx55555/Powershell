@echo off
:loop
set /p username=Enter the username (or type "done" to exit):
if "%username%"=="done" goto end
powershell -NoProfile -Command "Import-Module ActiveDirectory; Set-ADAccountPassword '%username%' -Reset"
if %errorlevel% equ 0 (
    echo Password reset successfully for user %username%.
) else (
    echo Password reset failed for user %username%. Please check the username and try again.
)
goto loop
:end
