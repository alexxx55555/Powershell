<#
.SYNOPSIS
    Creates a distribution group in Office 365 and adds members from a CSV file.

.DESCRIPTION
    This script creates a new distribution group in Exchange Online (Office 365) and populates it with members
    from a CSV file containing email addresses.

.PARAMETER CsvPath
    Path to the CSV file containing email addresses to add as members.
    The CSV must have an "EmailAddress" column.
    Default: C:\book1.csv

.PARAMETER GroupName
    The name of the distribution group to create.
    If not specified, will prompt interactively.

.PARAMETER GroupAlias
    The alias (email prefix) for the distribution group.
    If not specified, will prompt interactively.

.PARAMETER GroupType
    The type of distribution group to create (Distribution or Security).
    Default: Distribution

.EXAMPLE
    .\Create DL from csv file office 365.ps1
    Prompts for group name and alias, then creates the group using default CSV path.

.EXAMPLE
    .\Create DL from csv file office 365.ps1 -GroupName "Sales Team" -GroupAlias "salesteam" -CsvPath "C:\users.csv"
    Creates the distribution group with specified parameters.

.NOTES
    Author: IT Department
    Requires: ExchangeOnlineManagement module
    Prerequisites: Must be connected to Exchange Online (Connect-ExchangeOnline)
    CSV Format: Must have "EmailAddress" column
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if (Test-Path $_ -PathType Leaf) { $true }
        else { throw "CSV file not found: $_" }
    })]
    [string]$CsvPath = "C:\book1.csv",

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$GroupName,

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$GroupAlias,

    [Parameter(Mandatory = $false)]
    [ValidateSet('Distribution', 'Security')]
    [string]$GroupType = 'Distribution'
)

#Requires -Version 5.1

begin {
    Write-Host "=== Office 365 Distribution Group Creator ===" -ForegroundColor Cyan

    # Check if ExchangeOnlineManagement module is available
    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        Write-Warning "ExchangeOnlineManagement module not found. Attempting to install..."
        try {
            Install-Module -Name ExchangeOnlineManagement -Force -AllowClobber -Scope CurrentUser
            Write-Host "Module installed successfully" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to install ExchangeOnlineManagement module: $_"
            exit 1
        }
    }

    # Check if connected to Exchange Online
    try {
        $null = Get-OrganizationConfig -ErrorAction Stop
        Write-Verbose "Already connected to Exchange Online"
    }
    catch {
        Write-Host "Not connected to Exchange Online. Connecting..." -ForegroundColor Yellow
        try {
            Connect-ExchangeOnline -ErrorAction Stop
            Write-Host "Successfully connected to Exchange Online" -ForegroundColor Green
        }
        catch {
            Write-Error "Failed to connect to Exchange Online: $_"
            exit 1
        }
    }

    # Initialize counters
    $script:MembersAdded = 0
    $script:MembersFailed = 0
}

process {
    try {
        # Prompt for group name if not provided
        if (-not $GroupName) {
            $GroupName = Read-Host -Prompt "Please enter the distribution group name"
            if ([string]::IsNullOrWhiteSpace($GroupName)) {
                throw "Group name cannot be empty"
            }
        }

        # Prompt for group alias if not provided
        if (-not $GroupAlias) {
            $GroupAlias = Read-Host -Prompt "Please enter the distribution group alias"
            if ([string]::IsNullOrWhiteSpace($GroupAlias)) {
                throw "Group alias cannot be empty"
            }
        }

        # Check if group already exists
        $existingGroup = Get-DistributionGroup -Identity $GroupName -ErrorAction SilentlyContinue
        if ($existingGroup) {
            Write-Warning "Distribution group '$GroupName' already exists"
            $response = Read-Host "Do you want to add members to the existing group? (Y/N)"
            if ($response -ne 'Y') {
                Write-Host "Operation cancelled" -ForegroundColor Yellow
                return
            }
        }
        else {
            # Create the new distribution group
            Write-Host "`nCreating distribution group '$GroupName'..." -ForegroundColor Cyan
            try {
                New-DistributionGroup -Name $GroupName -Alias $GroupAlias -Type $GroupType -ErrorAction Stop
                Write-Host "Distribution group created successfully" -ForegroundColor Green
            }
            catch {
                Write-Error "Failed to create distribution group: $_"
                return
            }
        }

        # Import CSV file
        Write-Host "`nImporting members from CSV: $CsvPath" -ForegroundColor Cyan
        $members = Import-Csv -Path $CsvPath -ErrorAction Stop

        if ($members.Count -eq 0) {
            Write-Warning "No members found in CSV file"
            return
        }

        # Verify EmailAddress column exists
        if (-not ($members[0].PSObject.Properties.Name -contains 'EmailAddress')) {
            throw "CSV file must contain an 'EmailAddress' column"
        }

        Write-Host "Found $($members.Count) member(s) to process`n" -ForegroundColor Green

        # Add members to the distribution group
        foreach ($member in $members) {
            $emailAddress = $member.EmailAddress

            if ([string]::IsNullOrWhiteSpace($emailAddress)) {
                Write-Warning "Skipping empty email address"
                $script:MembersFailed++
                continue
            }

            try {
                # Check if member already exists in the group
                $existingMember = Get-DistributionGroupMember -Identity $GroupName | Where-Object { $_.PrimarySmtpAddress -eq $emailAddress }

                if ($existingMember) {
                    Write-Host "  [SKIPPED] $emailAddress - already a member" -ForegroundColor Yellow
                    continue
                }

                # Add member to group
                Add-DistributionGroupMember -Identity $GroupName -Member $emailAddress -ErrorAction Stop
                Write-Host "  [ADDED] $emailAddress" -ForegroundColor Green
                $script:MembersAdded++
            }
            catch {
                Write-Warning "  [FAILED] $emailAddress - $($_.Exception.Message)"
                $script:MembersFailed++
            }
        }
    }
    catch {
        Write-Error "An error occurred: $_"
        exit 1
    }
}

end {
    # Display summary
    Write-Host "`n========== SUMMARY ==========" -ForegroundColor Cyan
    Write-Host "Distribution Group: $GroupName" -ForegroundColor White
    Write-Host "Total members processed: $($script:MembersAdded + $script:MembersFailed)" -ForegroundColor White
    Write-Host "Successfully added: $script:MembersAdded" -ForegroundColor Green
    Write-Host "Failed/Skipped: $script:MembersFailed" -ForegroundColor Yellow
    Write-Host "============================`n" -ForegroundColor Cyan
}
