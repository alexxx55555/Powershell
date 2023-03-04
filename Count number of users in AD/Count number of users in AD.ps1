$OUpath = 'OU=Users,OU=Alex,DC=alex,DC=local'
$count = (Get-ADObject -Filter * -SearchBase $OUpath).Count 
Write-Host "The number of users in AD is: $count"
Get-ADUser -Filter * -SearchBase $OUpath | Select-object `
Name,UserPrincipalName,SamAccountName ` | Out-GridView
#| Export-Csv -NoType $ExportPath
#$ExportPath = 'c:\users_in_ou1.csv'

