$OUpath = 'OU=Users,OU=Alex,DC=alex,DC=local'

#| Export-Csv -NoType $ExportPath
#$ExportPath = 'c:\users_in_ou1.csv'
$count = (Get-ADObject -Filter * -SearchBase $OUpath).Count 
Write-Host "The number of users in AD is: $count"
