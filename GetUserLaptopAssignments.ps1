# Connect to Azure AD
#Connect-AzureAD

# Fetch all active, non-guest users
$activeNonGuestUsers = Get-AzureADUser -All $true | Where-Object { $_.AccountEnabled -eq $true -and $_.UserType -ne "Guest" }

# Initialize an array to store user and laptop info
$userLaptopInfo = @()

foreach ($user in $activeNonGuestUsers) {
    # Fetch devices associated with the user
    $devices = Get-AzureADUserRegisteredDevice -ObjectId $user.ObjectId

    # Filtering for Mac and Windows laptops
    # Adjust DeviceOSType values to match your Azure AD configuration
    $laptops = $devices | Where-Object  { $_.DeviceOSType -eq "Windows" -or $_.DeviceOSType -eq "MacOS" -or $_.DeviceOSType -eq "Mac" -or $_.DeviceOSType -eq "MacMDM"}

    # Get laptop names or IDs
    $laptopNames = $laptops | ForEach-Object { $_.DisplayName }

    # Create a custom object with user and laptop info
    $info = New-Object PSObject -property @{
        UserName = $user.DisplayName
        UserPrincipalName = $user.UserPrincipalName
        LaptopsAssigned = ($laptopNames -join ", ")
    }

    # Add the info to the array
    $userLaptopInfo += $info
}

# Export the data to a CSV file
$userLaptopInfo | Export-Csv -Path "c:\user_laptop_assignment.csv" -NoTypeInformation
