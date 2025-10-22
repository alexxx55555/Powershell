Connect-AzureAD

# Import CSV file with security groups
$csvFile = Import-Csv -Path "C:\book2.csv"

# Add new owner to each security group
foreach ($row in $csvFile) {
    $securityGroup = $row.SecurityGroup
    $ownerEmail = $row.OwnerEmail

    # Get group object
    $groupObject = Get-AzureADGroup -SearchString $securityGroup

    if ($groupObject -ne $null) {
        # Get the user object
        $userObject = Get-AzureADUser -ObjectId $ownerEmail

        if ($userObject -ne $null) {
            # Add owner to group
            Add-AzureADGroupOwner -ObjectId $groupObject.ObjectId -RefObjectId $userObject.ObjectId
            Write-Host "Added $ownerEmail as an owner to $securityGroup"
        } else {
            Write-Host "User $ownerEmail not found"
        }
    } else {
        Write-Host "Group $securityGroup not found"
    }
}




