$EXsession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ex2019.alex.local/powershell
Import-PSSession -session $EXsession

$SkypeSession = New-PSSession -Credential $Credentials -ConnectionURI https://Skype-Server.alex.local/OcsPowershell
Import-PSSession $SkypeSession

$password = ConvertTo-SecureString "12345" -AsPlainText -Force

Import-Csv C:\Users\vinokura\Desktop\users.csv | ForEach-Object {

New-Mailbox -Name $_.name `
-FirstName $_.FirstName `
-LastName $_.LastNAme `
-Alias $_.SamAccountName `
-UserPrincipalName $_.UserPrincipalName `
-Password $password `
-OrganizationalUnit alex.local/alex/users

}


Get-CsAdUser -Ou "alex.local/alex/users" -Filter `
{Enabled -ne $false} | Enable-CsUser -RegistrarPool "Skype-Server.alex.local" -SipAddressType SamAccountName -SipDomain "alex.local" 
Get-CsAdUser -OU "alex.local/alex/users" -Filter {Enabled -ne $false} | Measure-Object | FL Count 