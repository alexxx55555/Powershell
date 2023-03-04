# Teams Fix:
#   1. Quit Microsoft Teams & Outlook.
#	2. Delete the contents of the entire folder: %appdata%\Microsoft\Teams.
#	3. Restart Microsoft Teams.

if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
Write-Host "Ending Outlook & Teams Processes.." -ForegroundColor Cyan
Get-Process "Teams", "Outlook" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "Deleting Teams Temp files" -ForegroundColor Cyan
Get-ChildItem $env:appdata\Microsoft\Teams -Recurse | Remove-Item -Confirm:$false -Force -Recurse
Write-Host "Completed Successfully" -ForegroundColor Green
Write-Host "Opening Teams" -ForegroundColor Cyan
& $env:LOCALAPPDATA\Microsoft\Teams\Update.exe --processStart "Teams.exe"

# If running in the console, wait for input before closing.
if ($Host.Name -eq "ConsoleHost")
{
    Write-Host "`nPress any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}