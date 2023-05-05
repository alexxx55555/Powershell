# Connect to Exchange Management Shell
$s=New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ex2019.alex.local/powershell 
Import-PSSession -session $s -AllowClobber  -DisableNameChecking

$csvFilePath = "C:\book1.csv"
$groupName = Read-Host -Prompt "Please enter the distribution group name"
$groupAlias = Read-Host -Prompt "Please enter the distribution group alias"


# Create the new distribution group
New-DistributionGroup -Name $groupName -Alias $groupAlias -Type Distribution

# Import email addresses from CSV file and add them as members to the new distribution group
Import-Csv -Path $csvFilePath | ForEach-Object {
    $emailAddress = $_.EmailAddress
    Add-DistributionGroupMember -Identity $groupName -Member $emailAddress
}

# Remove the Exchange Management Shell session
Remove-PSSession $Session
