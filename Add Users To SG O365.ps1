# Import AzureAD Module
Import-Module AzureAD

# Connect to AzureAD
Connect-AzureAD

# Define the group object ID or name
$groupName = "App_FreshDesk_Users"

# Retrieve the group object
$group = Get-AzureADGroup -Filter "DisplayName eq '$groupName'"

if ($group -eq $null) {
    Write-Host "Group not found." -ForegroundColor Red
    exit
}

# Import the CSV file
$csvPath = "C:\List.csv"
$emailAddresses = Import-Csv -Path $csvPath

# Add each email to the group
foreach ($email in $emailAddresses) {
    try {
        $user = Get-AzureADUser -Filter "UserPrincipalName eq '$($email.Email)'"
        if ($user) {
            Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $user.ObjectId
            Write-Host "Added $($email.Email) to the group." -ForegroundColor Green
        } else {
            Write-Host "User $($email.Email) not found in Azure AD." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Failed to add $($email.Email): $_" -ForegroundColor Red
    }
}
