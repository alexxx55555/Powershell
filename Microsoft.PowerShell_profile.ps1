Start-Transcript | out-null

$s=New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ex2019.alex.local/powershell
Import-PSSession -session $s


IF (([Security.Principal.WindowsPrincipal] ` [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
$host.ui.RawUI.WindowTitle = "Alex's PowerShell - Running as ADMINISTRATOR"
}
Else
{
$host.ui.RawUI.WindowTitle = "Alex's PowerShell"
}
