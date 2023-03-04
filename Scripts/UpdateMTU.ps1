if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
Get-NetIPInterface -InterfaceAlias "_Common_Amdocs*" | Set-NetIPInterface -NlMtuBytes 1200
Get-NetIPInterface -InterfaceAlias "_Common_Amdocs*"

Write-Output "`nMTU changed successfully."
# If running in the console, wait for input before closing.
if ($Host.Name -eq "ConsoleHost")
{
    Write-Host "`nPress any key to continue..."
    $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
}