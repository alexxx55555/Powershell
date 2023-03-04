if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) `
{ Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }

# Imprt AD Module
Import-Module ActiveDirectory

# Grab Variables from User
$firstname = Read-Host -Prompt "Enter in the First Name"
$lastname = Read-Host  -Prompt  "Enter in the Last Name"

# Create the AD User
New-ADUser `
-Name "$firstname $lastname" `
-GivenName $firstname `
-Surname $lastname `
-UserPrincipalName "$firstname@alex.local" `
-SamAccountName "$firstname" `
-AccountPassword (ConvertTo-SecureString "12345" -AsPlainText -Force) `
-Path "OU=Users,OU=Alex,DC=alex,DC=local" `
-Enabled 1 