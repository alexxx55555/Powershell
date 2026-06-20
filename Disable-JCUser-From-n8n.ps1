param(
    [Parameter(Mandatory = $true)][string]$Username
)

# JumpCloud API configuration
$baseUrl = "https://console.jumpcloud.com/api"
$ApiKey = "jca_6Laq2ybRvaGKSdrU4YVogE58kwHhGR69Sjcw"

# Set headers
$headers = @{
    "x-api-key" = $ApiKey
    "Content-Type" = "application/json"
}

try {
    # Search for user by username
    $searchUrl = "$baseUrl/systemusers?filter=username:`$eq:$Username"
    $searchResponse = Invoke-RestMethod -Uri $searchUrl -Headers $headers -Method Get -ErrorAction Stop
    
    if (-not $searchResponse.results -or $searchResponse.results.Count -eq 0) {
        # User not found
        $result = @{
            Username      = $Username
            FullName      = ""
            Email         = ""
            Status        = "Not Found"
            Message       = "User not found. Please check the username and try again!"
            Suspended     = $false
            JCUserId      = ""
            GroupsRemoved = @()
        } | ConvertTo-Json -Compress
        Write-Output $result
        return
    }
    
    $user = $searchResponse.results[0]
    $userId = $user._id
    $fullName = "$($user.firstname) $($user.lastname)".Trim()
    $email = $user.email
    
    # Check if already suspended
    if ($user.suspended -eq $true) {
        $result = @{
            Username      = $Username
            FullName      = $fullName
            Email         = $email
            Status        = "Already Suspended"
            Message       = "This user account is already suspended."
            Suspended     = $true
            JCUserId      = $userId
            GroupsRemoved = @()
        } | ConvertTo-Json -Compress
        Write-Output $result
        return
    }
    
    # Get user's groups before removal
    $userGroupsUrl = "$baseUrl/v2/users/$userId/memberof"
    $userGroups = Invoke-RestMethod -Uri $userGroupsUrl -Headers $headers -Method Get -ErrorAction SilentlyContinue
    $removedGroups = @()
    
    if ($userGroups) {
        foreach ($groupAssoc in $userGroups) {
            if ($groupAssoc.type -eq "user_group") {
                # Get group details
                $groupUrl = "$baseUrl/v2/usergroups/$($groupAssoc.id)"
                $groupInfo = Invoke-RestMethod -Uri $groupUrl -Headers $headers -Method Get -ErrorAction SilentlyContinue
                if ($groupInfo) {
                    $removedGroups += $groupInfo.name
                }
                
                # Remove user from group
                $removeUrl = "$baseUrl/v2/usergroups/$($groupAssoc.id)/members"
                $removeBody = @{
                    op = "remove"
                    type = "user"
                    id = $userId
                } | ConvertTo-Json
                
                Invoke-RestMethod -Uri $removeUrl -Headers $headers -Method Post -Body $removeBody -ErrorAction SilentlyContinue
            }
        }
    }
    
    # Suspend the user
    $suspendUrl = "$baseUrl/systemusers/$userId"
    $suspendBody = @{
        suspended = $true
    } | ConvertTo-Json
    
    $suspendResponse = Invoke-RestMethod -Uri $suspendUrl -Headers $headers -Method Put -Body $suspendBody -ErrorAction Stop
    
    # Output success result
    $result = @{
        Username      = $Username
        FullName      = $fullName
        Email         = $email
        Status        = "Success"
        Message       = "User account successfully suspended"
        Suspended     = $true
        JCUserId      = $userId
        GroupsRemoved = $removedGroups
    } | ConvertTo-Json -Compress
    Write-Output $result
}
catch {
    # Generic error handling
    $errorResult = @{
        Username      = $Username
        FullName      = ""
        Email         = ""
        Status        = "Error"
        Message       = "Failed to suspend user: $($_.Exception.Message)"
        Suspended     = $false
        JCUserId      = ""
        GroupsRemoved = @()
    } | ConvertTo-Json -Compress
    Write-Output $errorResult
}