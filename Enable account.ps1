<#
.SYNOPSIS
    Enables a disabled Active Directory user account.

.DESCRIPTION
    This script enables a disabled AD user account by username or display name.
    It validates that the user exists before attempting to enable the account.

.PARAMETER Username
    The username (SamAccountName) or display name of the user to enable.
    If not specified, will prompt interactively.

.EXAMPLE
    .\Enable account.ps1
    Prompts for username and enables the account.

.EXAMPLE
    .\Enable account.ps1 -Username "jdoe"
    Enables the account for user jdoe.

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
        $Username = Read-Host -Prompt "Enter the user account to enable"
    }

    if ([string]::IsNullOrWhiteSpace($Username)) {
        Write-Error "Username cannot be empty"
        return
    }

    try {
        # Try to find the user by SamAccountName or DisplayName
        $user = Get-ADUser -Filter "SamAccountName -eq '$Username' -or DisplayName -eq '$Username' -or Name -eq '$Username'" -Properties Enabled -ErrorAction Stop

        if (-not $user) {
            Write-Error "User '$Username' not found in Active Directory"
            return
        }

        # Check if user is already enabled
        if ($user.Enabled) {
            Write-Host "User '$($user.SamAccountName)' ($($user.Name)) is already enabled" -ForegroundColor Yellow
            return
        }

        # Enable the account
        Enable-ADAccount -Identity $user -ErrorAction Stop
        Write-Host "Successfully enabled account for '$($user.SamAccountName)' ($($user.Name))" -ForegroundColor Green

        # Verify the account is enabled
        $verifyUser = Get-ADUser -Identity $user -Properties Enabled
        if ($verifyUser.Enabled) {
            Write-Host "Account status verified: ENABLED" -ForegroundColor Green
        }
        else {
            Write-Warning "Account may not be fully enabled. Please verify manually."
        }
    }
    catch {
        Write-Error "Failed to enable account for '$Username': $_"
    }
}
