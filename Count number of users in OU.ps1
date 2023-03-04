$OUpath = 'OU=Users,OU=Alex,DC=alex,DC=local'
Get-ADUser -Filter * -SearchBase $OUpath | Select-object `
Name,UserPrincipalName,SamAccountName `
#| Export-Csv -NoType $ExportPath
#$ExportPath = 'c:\users_in_ou1.csv'
$count = (Get-ADObject -Filter * -SearchBase $OUpath).Count 
Write-Host "The count is $count"
