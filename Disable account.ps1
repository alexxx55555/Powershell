<#
.SYNOPSIS
    Disables an Active Directory user account.

.DESCRIPTION
    This script disables an AD user account by username or display name.
    It validates that the user exists before attempting to disable the account.

.PARAMETER Username
    The username (SamAccountName) or display name of the user to disable.
    If not specified, will prompt interactively.

.PARAMETER Confirm
    Prompts for confirmation before disabling the account.

.EXAMPLE
    .\Disable account.ps1
    Prompts for username and disables the account.

.EXAMPLE
    .\Disable account.ps1 -Username "jdoe" -Confirm:$false
    Disables the account for user jdoe without confirmation.

.NOTES
    Author: IT Department
    Requires: ActiveDirectory module
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
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
        $Username = Read-Host -Prompt "Enter the user account to disable"
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

        # Check if user is already disabled
        if (-not $user.Enabled) {
            Write-Host "User '$($user.SamAccountName)' ($($user.Name)) is already disabled" -ForegroundColor Yellow
            return
        }

        # Disable the account with confirmation
        if ($PSCmdlet.ShouldProcess($user.Name, "Disable Active Directory account")) {
            Disable-ADAccount -Identity $user -ErrorAction Stop
            Write-Host "Successfully disabled account for '$($user.SamAccountName)' ($($user.Name))" -ForegroundColor Green

            # Verify the account is disabled
            $verifyUser = Get-ADUser -Identity $user -Properties Enabled
            if (-not $verifyUser.Enabled) {
                Write-Host "Account status verified: DISABLED" -ForegroundColor Green
            }
            else {
                Write-Warning "Account may not be fully disabled. Please verify manually."
            }
        }
    }
    catch {
        Write-Error "Failed to disable account for '$Username': $_"
    }
}
