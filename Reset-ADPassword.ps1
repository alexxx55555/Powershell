param([string]$Username)
$NewPass = "Temp" + (Get-Random -Minimum 1000 -Maximum 9999) + "!"
Set-ADAccountPassword -Identity $Username -NewPassword (ConvertTo-SecureString $NewPass -AsPlainText -Force) -Reset
Set-ADUser -Identity $Username -ChangePasswordAtLogon $true
Write-Output "SUCCESS: Password for $Username reset to $NewPass"