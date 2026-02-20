
Set-ADUser -Identity "joshc" -Replace @{pwdLastSet=-0}
Get-ADUser -Identity "ash" -Properties PasswordNeverExpires, pwdLastSet | Select Name, PasswordNeverExpires, pwdLastSet


Get-ADUser -Identity "ash" -Properties DistinguishedName | Select Name, DistinguishedName