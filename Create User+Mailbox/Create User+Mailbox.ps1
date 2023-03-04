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