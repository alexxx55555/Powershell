#requires -Version 5.0
#requires -Modules ActiveDirectory

<#
.SYNOPSIS
    Lightweight AD Account Unlock Script optimized for n8n integration
    
.DESCRIPTION
    Minimal, fast unlock script designed for webhook/automation platforms.
    Outputs JSON format directly for n8n consumption.
    
.PARAMETER Username
    Username to unlock
    
.PARAMETER LogPath
    Log directory (default: C:\Logs\AD-Unlock)
    
.EXAMPLE
    .\Unlock-ADAccount-n8n.ps1 -Username "jsmith"
#>

param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [string]$Username,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = "C:\Logs\AD-Unlock",
    
    [Parameter(Mandatory = $false)]
    [string]$Reason = "Automated unlock via n8n"
)

$ErrorActionPreference = 'Stop'

# Create log directory if needed
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = Join-Path $LogPath "unlock-$(Get-Date -Format 'yyyy-MM-dd').log"
$Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Function to write to log
function Add-LogEntry {
    param([string]$Message)
    "$Timestamp | $Message" | Add-Content -Path $LogFile -Encoding UTF8
}

# Function to return JSON result
function Return-Result {
    param(
        [bool]$Success,
        [string]$Message,
        [string]$Details = ""
    )
    
    @{
        success = $Success
        username = $Username
        message = $Message
        details = $Details
        timestamp = $Timestamp
        domain = (Get-ADDomain).DNSRoot
        logFile = $LogFile
    } | ConvertTo-Json -Depth 2
}

try {
    Add-LogEntry "Unlock attempt for: $Username (Reason: $Reason)"
    
    # Check if account exists
    $user = Get-ADUser -Identity $Username -Properties LockedOut, DisplayName, BadLogonCount -ErrorAction Stop
    Add-LogEntry "Account found: $($user.DisplayName)"
    
    # Check if locked
    if ($user.LockedOut -eq $false) {
        Add-LogEntry "Account already unlocked"
        Return-Result -Success $true -Message "Account was already unlocked" -Details "No unlock action needed"
        exit 0
    }
    
    # Unlock the account
    Unlock-ADAccount -Identity $Username -ErrorAction Stop
    Add-LogEntry "Unlock command executed for: $Username"
    
    # Verify unlock was successful
    Start-Sleep -Milliseconds 300
    $userAfter = Get-ADUser -Identity $Username -Properties LockedOut
    
    if ($userAfter.LockedOut -eq $false) {
        Add-LogEntry "SUCCESS: $Username unlocked (was locked after $($user.BadLogonCount) failed attempts)"
        Return-Result -Success $true -Message "Account successfully unlocked" -Details "Failed login attempts: $($user.BadLogonCount)"
        exit 0
    }
    else {
        Add-LogEntry "FAILED: Account still locked after unlock attempt"
        Return-Result -Success $false -Message "Unlock command executed but account still locked" -Details "This may indicate a replication delay"
        exit 1
    }
}
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
    Add-LogEntry "FAILED: Account not found - $Username"
    Return-Result -Success $false -Message "Account not found in Active Directory" -Details "Username: $Username"
    exit 1
}
catch {
    Add-LogEntry "ERROR: $($_.Exception.Message)"
    Return-Result -Success $false -Message "Error during unlock" -Details $_.Exception.Message
    exit 1
}