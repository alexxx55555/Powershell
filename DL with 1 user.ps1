# Connect to Exchange Online
#Connect-ExchangeOnline

# Function to get the number of group members
Function Get-DLMemberCount {
    param (
        [string]$DLEmailAddress
    )
    try {
        $members = Get-DistributionGroupMember -Identity $DLEmailAddress -ErrorAction Stop
        $count = @($members).Count
        Write-Host "Checking $DLEmailAddress with $count members."
        return $count
    } catch {
        Write-Host "Error fetching members for $DLEmailAddress. Error: $($_.Exception.Message)"
        return 0
    }
}

# Function to get the owner of the group
Function Get-DLOwner {
    param (
        [string]$DLEmailAddress
    )
    try {
        $group = Get-DistributionGroup -Identity $DLEmailAddress -ErrorAction Stop
        return $group.ManagedBy
    } catch {
        Write-Host "Error fetching owner for $DLEmailAddress. Error: $($_.Exception.Message)"
        return $null
    }
}

# ------------ Distribution Lists ------------
$distributionGroups = @()
Get-DistributionGroup | ForEach-Object {
    $emailAddress = $_.PrimarySmtpAddress
    $count = Get-DLMemberCount -DLEmailAddress $emailAddress
    $owner = Get-DLOwner -DLEmailAddress $emailAddress
    if ($count -eq 1) {
        $distributionGroups += [PSCustomObject]@{
            ObjectId      = $_.ExternalDirectoryObjectId
            DisplayName   = $_.DisplayName
            EmailAddress  = $emailAddress
            GroupType     = "DistributionList"
            MemberCount   = $count
            Owner         = $owner
        }
    }
}
$distributionGroups | Export-Csv -Path 'c:\DistributionListsWithOneMember2.csv' -NoTypeInformation

Write-Host "Script execution completed."
