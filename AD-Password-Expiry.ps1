# AD-Password-Expiry.ps1
# Queries Active Directory for users with passwords expiring within specified days
# Scope: OU=Users,OU=Alex,DC=alex,DC=local
try {
    # Configuration
    $ErrorActionPreference = "Continue"
    $WarningPreference = "SilentlyContinue"
    
    $domainName = (Get-ADDomain).DNSRoot
    $maxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge.Days
    # Target OU: alex.local/Alex/Users
    $targetOU = "OU=Users,OU=Alex,DC=alex,DC=local"
    $daysThreshold = 14  # Alert for passwords expiring within 14 days
    # Get all enabled users from the specific OU with password-related attributes
    Write-Host "Querying OU: $targetOU"
    
    $users = @(Get-ADUser -Filter "Enabled -eq `$true" `
        -SearchBase $targetOU `
        -Properties "msDS-UserPasswordExpiryTimeComputed", "displayName", "mail", "pwdLastSet", "lastLogonTimestamp", "PasswordNeverExpires" `
        -ErrorAction Stop)
    Write-Host "Found $($users.Count) enabled users in target OU"
    $expiringUsers = @()
    $totalUsers = $users.Count
    foreach ($user in $users) {
        try {
            # Skip if user has PasswordNeverExpires flag set
            if ($user.PasswordNeverExpires -eq $true) {
                Write-Host "Skipping $($user.SamAccountName) - password never expires (flag)"
                continue
            }

            # Get the expiry timestamp from the user object
            $expiryTimestamp = $user."msDS-UserPasswordExpiryTimeComputed"
            
            # Skip if password never expires (max int64 timestamp)
            if ($expiryTimestamp -eq 9223372036854775807) {
                Write-Host "Skipping $($user.SamAccountName) - password never expires (timestamp)"
                continue
            }

            # Handle pwdLastSet = 0 (password is expired / must change at next login)
            if ($null -eq $expiryTimestamp -or $expiryTimestamp -eq 0 -or $expiryTimestamp -lt 1) {
                Write-Host "User: $($user.SamAccountName), Days remaining: 0 (password expired / must change)"
                $expiringUsers += @{
                    Username = $user.SamAccountName
                    FullName = if ($user.DisplayName) { $user.DisplayName } else { $user.Name }
                    Email = if ($user.Mail) { $user.Mail } else { "N/A" }
                    ExpiryDate = (Get-Date).ToString('d.M.yyyy h:mm tt')
                    DaysUntilExpiry = 0
                    LastPasswordChange = "Never"
                    PasswordNeverExpires = $false
                }
                Write-Host "Added $($user.SamAccountName) to alert list - password expired / must change"
                continue
            }

            # Convert timestamp to date
            $expiryDate = [DateTime]::FromFileTime($expiryTimestamp)
            $today = Get-Date
            $daysRemaining = [Math]::Ceiling(($expiryDate - $today).TotalDays)
            
            Write-Host "User: $($user.SamAccountName), Days remaining: $daysRemaining"
            
            # Include users with passwords expiring within threshold or already expired
            if ($daysRemaining -le $daysThreshold) {
                $pwdLastSetTime = if ($user.pwdLastSet -and $user.pwdLastSet -ne 0) {
                    [DateTime]::FromFileTime($user.pwdLastSet).ToString('d.M.yyyy h:mm tt')
                } else {
                    "Never"
                }
                $expiringUsers += @{
                    Username = $user.SamAccountName
                    FullName = if ($user.DisplayName) { $user.DisplayName } else { $user.Name }
                    Email = if ($user.Mail) { $user.Mail } else { "N/A" }
                    ExpiryDate = $expiryDate.ToString('d.M.yyyy h:mm tt')
                    DaysUntilExpiry = [int]$daysRemaining
                    LastPasswordChange = $pwdLastSetTime
                    PasswordNeverExpires = $false
                }
                
                Write-Host "Added $($user.SamAccountName) to alert list - expires in $daysRemaining days"
            }
        }
        catch {
            Write-Error "Error processing user $($user.SamAccountName): $_" -ErrorAction Continue
        }
    }
    Write-Host "Found $($expiringUsers.Count) users with passwords expiring within $daysThreshold days"
    # Build output object
    $output = @{
        ScanTime = (Get-Date).ToString('d.M.yyyy h:mm tt')
        DomainName = $domainName
        TargetOU = $targetOU
        MaxPasswordAge = $maxPasswordAge
        DaysThreshold = $daysThreshold
        UsersScanned = $totalUsers
        UsersExpiring = $expiringUsers.Count
        Data = $expiringUsers
    }
    # Output as JSON
    $output | ConvertTo-Json -Depth 10 -ErrorAction Stop
}
catch {
    Write-Error "Fatal error: $_" -ErrorAction Continue
    # Return empty array on error
    @{
        ScanTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
        TargetOU = "OU=Users,OU=Alex,DC=alex,DC=local"
        Data = @()
        Error = $_.Exception.Message
    } | ConvertTo-Json -Depth 10
}