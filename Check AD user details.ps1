function Convert-UserFilter {
    param (
        [Parameter(Mandatory = $true)]
        [string]$username
    )
    
    if ($username -split '\s+' -ne '') {
        "DisplayName -eq '$username' -or SamAccountName -eq '$username'"
    } else {
        "SamAccountName -eq '$username'"
    }
}


while ($true) {
    $username = Read-Host -Prompt 'Please enter a username'
    $username = $username.Trim()
    
    if ([string]::IsNullOrWhiteSpace($username)) {
        break
    }
    
    $statement = Convert-UserFilter -username $username
    $user = Get-ADUser -Filter $statement -Properties PasswordExpired, CN, DisplayName, CanonicalName, LockedOut, msRTCSIP-PrimaryUserAddress, memberof, msExchArchiveStatus, EmailAddress, PasswordLastSet

    
    if ($user) {
        Write-Host -ForegroundColor Green "User '$username' Details:"
       $user | Select-Object @{
        Name = "Username"
        Expression = { $_.SamAccountName }
    },
    @{
        Name = "Display Name <> CN"
        Expression = {
            $compareDisplayCN = if ($_.DisplayName -eq $_.CN) { "Same" } else { "Different" }
            $_.DisplayName, $_.CN -join " < $compareDisplayCN > "
        }
    },
    @{
        Name = "Email Address"
        Expression = { $_.EmailAddress }
    },
    @{
        Name = "Password Last Set"
        Expression = {
            if ($_.PasswordLastSet -ne $null) {
                $_.PasswordLastSet.ToString("dd-MM-yyyy HH:mm:ss") 
            } else {
                "Not available"
            }
        }
    },
    @{
        Name = "OU"
        Expression = { ($_.CanonicalName -replace '/|alex\.local\\', '/') -replace '^.*?(?=OU=)' }
    },
    @{
        Name = "SIP (Skype) Address"
        Expression = { $_."msRTCSIP-PrimaryUserAddress".Split(':')[1] }
    },
    @{
        Name = "IsPasswordExpired"
        Expression = { $_.PasswordExpired }
    },
    @{
        Name = "IsUserLocked"
        Expression = { $_.LockedOut }
    },
    @{
        Name = "Enabled"
        Expression = { $_.Enabled }
    },
    @{
        Name = "Distribution List:"
        Expression = {
            $groups = foreach ($group in $_.memberof) {
                $groupName = $group -replace '^.+?=(.+?),.+', '$1'
                try {
                    $groupObj = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction Stop
                    if ($groupObj.GroupCategory -eq 'Distribution') {
                        $groupName
                    }
                } catch {
                    Write-Warning "Error retrieving group information for '$groupName': $_"
                }
            }
            $groups -join "`n"
        }
    },
    @{
        Name = "Security Groups:"
        Expression = {
            $groups = foreach ($group in $_.memberof) {
                $groupName = $group -replace '^.+?=(.+?),.+', '$1'
                try {
                    $groupObj = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction Stop
                    if ($groupObj.GroupCategory -eq 'Security') {
                        $groupName
                    }
                } catch {
                    Write-Warning "Error retrieving group information for '$groupName': $_"
                }
            }
            $groups -join "`n"
        }
    }

    } else {
        Write-Host -ForegroundColor Red "The user '$username' does not exist. Please check that you have typed the correct username."
    }
}

Read-Host -Prompt 'Press Enter to Exit'
