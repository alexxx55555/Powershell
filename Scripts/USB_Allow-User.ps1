#Deny_Write = 1 is blocking USB Storage
#Deny_Write = 0 is allowing USB Storage
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
Write-Host "##############################################################################" -ForegroundColor Red
Write-Host "Please make sure to disconnect any external device prior to running the script" -ForegroundColor Red
Write-Host "##############################################################################" -ForegroundColor Red
Write-Host -NoNewLine 'Press any key to continue...';
$Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyUp") > $null

$regKeys = "{53f56308-b6bf-11d0-94f2-00a0c91efb8b}","{53f5630b-b6bf-11d0-94f2-00a0c91efb8b}", "{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}", "{53f56311-b6bf-11d0-94f2-00a0c91efb8b}",
"{6AC27878-A6FA-4155-BA85-F98F491D4F33}", "{F33FDC04-D1AC-4E8E-9A30-19BBd4B108AE}"
$date = Get-Date

foreach($key in $regKeys){
    if (Test-Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\$key")
    {
        New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\$key" -Name "Deny_Write" -Value "0" -PropertyType dword -Force -ErrorAction Continue 2>&1
        New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\$key" -Name "Date" -Value $date -PropertyType string -Force -ErrorAction Continue 2>&1
    }
    else
    {
        New-Item "HKCU:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\$key" -Force | New-ItemProperty -Name "Deny_Write" -Value "0" -PropertyType dword -Force -ErrorAction Continue 2>&1
        New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\$key" -Name "Date" -Value $date -PropertyType string -Force -ErrorAction Continue 2>&1
    }
}