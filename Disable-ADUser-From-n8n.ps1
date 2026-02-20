param(
    [Parameter(Mandatory = $true)][string]$Username
)

Import-Module ActiveDirectory

try {
    # Try to get the user
    $user = Get-ADUser -Identity $Username -Properties Enabled, DisplayName, MemberOf -ErrorAction Stop
    
    if (-not $user) {
        # User object is null (shouldn't happen with ErrorAction Stop, but just in case)
        $result = @{
            Username      = $Username
            FullName      = ""
            Status        = "Not Found"
            Message       = "User not found. Please check the username and try again!"
            Disabled      = $false
            GroupsRemoved = @()
            MovedToOU     = ""
        } | ConvertTo-Json -Compress
        Write-Output $result
        return
    }
    
    if ($user.Enabled -eq $false) {
        # Already disabled
        $result = @{
            Username      = $Username
            FullName      = $user.DisplayName
            Status        = "Already Disabled"
            Message       = "ℹ️ This user account is already disabled."
            Disabled      = $false
            GroupsRemoved = @()
            MovedToOU     = ""
        } | ConvertTo-Json -Compress
        Write-Output $result
        return
    }
    
    # Disable account
    Disable-ADAccount -Identity $Username
    
    # Collect and remove groups
    $removedGroups = @()
    foreach ($g in $user.MemberOf) {
        $groupName = (Get-ADGroup $g).Name
        $removedGroups += $groupName
        Remove-ADGroupMember -Identity $g -Members $Username -Confirm:$false
    }
    
    # Move user to Disabled Users OU
    $targetOU = "OU=Disabled Users,OU=Alex,DC=alex,DC=local"
    Move-ADObject -Identity $user.DistinguishedName -TargetPath $targetOU
    
    # Get only the OU name
    $ouName = ($targetOU -split ',')[0] -replace '^OU=', ''
    
    # Output JSON
    $result = @{
        Username      = $Username
        FullName      = $user.DisplayName
        Status        = "Success"
        Message       = "✅ User account successfully disabled"
        Disabled      = $true
        GroupsRemoved = $removedGroups
        MovedToOU     = $ouName
    } | ConvertTo-Json -Compress
    Write-Output $result
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    # Specific exception for user not found
    $errorResult = @{
        Username      = $Username
        FullName      = ""
        Status        = "Not Found"
        Message       = "User not found. Please check the username and try again!"
        Disabled      = $false
        GroupsRemoved = @()
        MovedToOU     = ""
    } | ConvertTo-Json -Compress
    Write-Output $errorResult
}
catch {
    # Generic error handling
    $errorResult = @{
        Username      = $Username
        FullName      = ""
        Status        = "Error"
        Message       = "❌ Failed to disable user: $($_.Exception.Message)"
        Disabled      = $false
        GroupsRemoved = @()
        MovedToOU     = ""
    } | ConvertTo-Json -Compress
    Write-Output $errorResult
}