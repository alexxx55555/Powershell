# Connect to MSOnline
Connect-MsolService -Credential $credential

# Connect to Azure AD
Connect-AzureAD -Credential $credential

$allGroups = @()

# Get Security Groups
Get-MsolGroup -All | Where-Object { $_.GroupType -eq "Security" } | ForEach-Object {
    $allGroups += New-Object PSObject -Property @{
        ObjectId = $_.ObjectId
        DisplayName = $_.DisplayName
        EmailAddress = $_.EmailAddress
        GroupType = "Security"
    }
}

# Get Distribution Groups
Get-MsolGroup -All | Where-Object { $_.GroupType -eq "DistributionList" } | ForEach-Object {
    $allGroups += New-Object PSObject -Property @{
        ObjectId = $_.ObjectId
        DisplayName = $_.DisplayName
        EmailAddress = $_.EmailAddress
        GroupType = "Distribution"
    }
}

# Get Office 365 Groups
Get-AzureADMSGroup -All | ForEach-Object {
    $allGroups += New-Object PSObject -Property @{
        ObjectId = $_.Id
        DisplayName = $_.DisplayName
        EmailAddress = $_.Mail
        GroupType = "Office365"
    }
}

$allGroups | Export-Csv -Path 'AllGroups.csv' -NoTypeInformation

# Check for groups with no members
$emptyGroups = @()
foreach ($group in $allGroups) {
    $members = Get-MsolGroupMember -GroupObjectId $group.ObjectId -All
    if ($members.Count -eq 0) {
        $emptyGroups += $group
    }
}
$emptyGroups | Export-Csv -Path 'EmptyGroups.csv' -NoTypeInformation

Write-Host "Script execution completed."
