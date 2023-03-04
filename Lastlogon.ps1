Get-ADUser -Filter * -SearchBase "OU=Users,OU=Alex,DC=alex,DC=local" -Properties LastLogonTimeStamp |
Select-Object Name,@{Name="Stamp"; Expression={[DateTime]::FromFileTime($_.lastLogonTimestamp).ToString('yyyy-MM-dd_hh:mm:ss')}} 
