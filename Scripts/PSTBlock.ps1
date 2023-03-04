if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
Write-Host "##############################################################################" -ForegroundColor Red
Write-Host "Closing Outlook and Removing relevant Reg Keys." -ForegroundColor Red
Write-Host "##############################################################################" -ForegroundColor Red
Write-Host -NoNewLine 'Press any key to continue...';
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null

Get-Process "Outlook" -ErrorAction SilentlyContinue | Stop-Process -Force
Remove-Item -Path "HKCU:\Software\Policies\Microsoft\office\16.0\outlook\pst" -Recurse -Force
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Office\16.0\Outlook\PST\" -Name "PSTDisableGrow" -Force 

Write-Host "`n##############################################################################" -ForegroundColor Green
Write-Host "Done successfully." -ForegroundColor Green
Write-Host "##############################################################################" -ForegroundColor Green
Write-Host -NoNewLine 'Press any key to continue...';
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null
Remove-Item -LiteralPath $MyInvocation.MyCommand.Path -Force