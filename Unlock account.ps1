<#
.SYNOPSIS
    Unlocks a locked Active Directory user account.

.DESCRIPTION
    This script unlocks a locked AD user account by username or display name.
    It validates that the user exists and is locked before attempting to unlock the account.

.PARAMETER Username
    The username (SamAccountName) or display name of the user to unlock.
    If not specified, will prompt interactively.

.EXAMPLE
    .\Unlock account.ps1
    Prompts for username and unlocks the account.

.EXAMPLE
    .\Unlock account.ps1 -Username "jdoe"
    Unlocks the account for user jdoe.

.NOTES
    Author: IT Department
    Requires: ActiveDirectory module
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Username
)

#Requires -Modules ActiveDirectory
#Requires -Version 5.1

begin {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Verbose "Active Directory module loaded successfully"
    }
    catch {
        Write-Error "Failed to load Active Directory module: $_"
        exit 1
    }
}

process {
    # Prompt for username if not provided
    if (-not $Username) {
        $Username = Read-Host -Prompt "Enter the user account to unlock"
    }

    if ([string]::IsNullOrWhiteSpace($Username)) {
        Write-Error "Username cannot be empty"
        return
    }

    try {
        # Try to find the user by SamAccountName or DisplayName
        $user = Get-ADUser -Filter "SamAccountName -eq '$Username' -or DisplayName -eq '$Username' -or Name -eq '$Username'" -Properties LockedOut, Enabled -ErrorAction Stop

        if (-not $user) {
            Write-Error "User '$Username' not found in Active Directory"
            return
        }

        # Check if user is locked
        if (-not $user.LockedOut) {
            Write-Host "User '$($user.SamAccountName)' ($($user.Name)) is not locked" -ForegroundColor Yellow
            return
        }

        # Unlock the account
        Unlock-ADAccount -Identity $user -ErrorAction Stop
        Write-Host "Successfully unlocked account for '$($user.SamAccountName)' ($($user.Name))" -ForegroundColor Green

        # Verify the account is unlocked
        $verifyUser = Get-ADUser -Identity $user -Properties LockedOut
        if (-not $verifyUser.LockedOut) {
            Write-Host "Account status verified: UNLOCKED" -ForegroundColor Green
        }
        else {
            Write-Warning "Account may still be locked. Please verify manually or check for additional security policies."
        }

        # Display additional info
        if (-not $user.Enabled) {
            Write-Warning "Note: Account is unlocked but still DISABLED. Use Enable-ADAccount to enable it."
        }
    }
    catch {
        Write-Error "Failed to unlock account for '$Username': $_"
    }
}
