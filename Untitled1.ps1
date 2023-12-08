# Connect to MSOnline
Connect-MsolService -Credential $credential

# Connect to Azure AD
Connect-AzureAD -Credential $credential

# Function to get the first owner's UPN
Function Get-FirstOwnerUPN {
    param (
        [string]$GroupObjectId
    )
    $owners = Get-AzureADGroupOwner -ObjectId $GroupObjectId
    if ($owners) {
        return $owners[0].UserPrincipalName
    }
    return "No owner found"
}

# ------------ Security Groups ------------
$securityGroups = @()
Get-MsolGroup -All | Where-Object { $_.GroupType -eq "Security" } | ForEach-Object {
    $owner = Get-FirstOwnerUPN -GroupObjectId $_.ObjectId
    $securityGroups += New-Object PSObject -Property @{
        ObjectId = $_.ObjectId
        DisplayName = $_.DisplayName
        EmailAddress = $_.EmailAddress
        GroupType = "Security"
        Owner = $owner
    }
}
$securityGroups | Export-Csv -Path 'SecurityGroups.csv' -NoTypeInformation

# ------------ Distribution Lists ------------
$distributionGroups = @()
Get-MsolGroup -All | Where-Object { $_.GroupType -eq "DistributionList" } | ForEach-Object {
    $owner = Get-FirstOwnerUPN -GroupObjectId $_.ObjectId
    $distributionGroups += New-Object PSObject -Property @{
        ObjectId = $_.ObjectId
        DisplayName = $_.DisplayName
        EmailAddress = $_.EmailAddress
        GroupType = "Distribution"
        Owner = $owner
    }
}
$distributionGroups | Export-Csv -Path 'DistributionGroups.csv' -NoTypeInformation

# ------------ Microsoft 365 Groups ------------
$office365Groups = @()
Get-AzureADMSGroup -All | ForEach-Object {
    $owner = Get-FirstOwnerUPN -GroupObjectId $_.Id
    $office365Groups += New-Object PSObject -Property @{
        ObjectId = $_.Id
        DisplayName = $_.DisplayName
        EmailAddress = $_.Mail
        GroupType = "Office365"
        Owner = $owner
    }
}
$office365Groups | Export-Csv -Path 'Office365Groups.csv' -NoTypeInformation

Write-Host "Script execution completed."