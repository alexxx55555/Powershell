<#
.SYNOPSIS
    Creates new computer objects in Active Directory from a CSV file.

.DESCRIPTION
    This script imports computer information from a CSV file and creates corresponding computer objects in Active Directory.
    The CSV file must contain the required fields for New-ADComputer cmdlet (at minimum: Name, SamAccountName).

.PARAMETER CsvPath
    The path to the CSV file containing computer information.
    Default: C:\AD User\computers.csv

.PARAMETER OrganizationalUnit
    Optional. The distinguished name of the OU where computers should be created.
    If not specified, computers will be created in the default computers container.

.PARAMETER WhatIf
    Shows what would happen if the script runs without actually creating the computers.

.EXAMPLE
    .\Create New Computer from CSV file.ps1
    Creates computers from the default CSV file location.

.EXAMPLE
    .\Create New Computer from CSV file.ps1 -CsvPath "C:\Temp\newcomps.csv" -OrganizationalUnit "OU=Workstations,DC=contoso,DC=com"
    Creates computers from specified CSV in the specified OU.

.EXAMPLE
    .\Create New Computer from CSV file.ps1 -WhatIf
    Shows what computers would be created without actually creating them.

.NOTES
    Author: IT Department
    Requires: ActiveDirectory module
    CSV Format Example:
        Name,SamAccountName,Description
        COMPUTER01,COMPUTER01,Sales Department PC
        COMPUTER02,COMPUTER02,HR Department PC
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if (Test-Path $_ -PathType Leaf) { $true }
        else { throw "CSV file not found: $_" }
    })]
    [string]$CsvPath = 'C:\AD User\computers.csv',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$OrganizationalUnit
)

#Requires -Modules ActiveDirectory
#Requires -Version 5.1

begin {
    # Import Active Directory module
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Verbose "Active Directory module loaded successfully"
    }
    catch {
        Write-Error "Failed to load Active Directory module: $_"
        exit 1
    }

    # Initialize counters
    $script:SuccessCount = 0
    $script:FailureCount = 0
    $script:Results = @()
}

process {
    try {
        # Import CSV file
        Write-Host "Importing computer data from: $CsvPath" -ForegroundColor Cyan
        $computers = Import-Csv -Path $CsvPath -ErrorAction Stop

        if ($computers.Count -eq 0) {
            Write-Warning "No computers found in CSV file"
            return
        }

        Write-Host "Found $($computers.Count) computer(s) to process" -ForegroundColor Green

        # Process each computer
        foreach ($computer in $computers) {
            $computerName = $computer.Name -or $computer.SamAccountName

            if (-not $computerName) {
                Write-Warning "Skipping row with missing Name/SamAccountName"
                $script:FailureCount++
                continue
            }

            try {
                # Check if computer already exists
                $existingComputer = Get-ADComputer -Filter "Name -eq '$computerName'" -ErrorAction SilentlyContinue

                if ($existingComputer) {
                    Write-Warning "Computer '$computerName' already exists in AD - skipping"
                    $script:Results += [PSCustomObject]@{
                        ComputerName = $computerName
                        Status       = 'Skipped'
                        Reason       = 'Already exists'
                    }
                    $script:FailureCount++
                    continue
                }

                # Prepare parameters for New-ADComputer
                $adParams = @{
                    Name        = $computer.Name
                    ErrorAction = 'Stop'
                }

                # Add optional parameters if they exist in CSV
                if ($computer.SamAccountName) { $adParams['SamAccountName'] = $computer.SamAccountName }
                if ($computer.Description) { $adParams['Description'] = $computer.Description }
                if ($computer.Location) { $adParams['Location'] = $computer.Location }
                if ($computer.ManagedBy) { $adParams['ManagedBy'] = $computer.ManagedBy }
                if ($OrganizationalUnit) { $adParams['Path'] = $OrganizationalUnit }

                # Create the computer
                if ($PSCmdlet.ShouldProcess($computerName, "Create computer in Active Directory")) {
                    New-ADComputer @adParams
                    Write-Host "  [SUCCESS] Created computer: $computerName" -ForegroundColor Green
                    $script:Results += [PSCustomObject]@{
                        ComputerName = $computerName
                        Status       = 'Success'
                        Reason       = 'Created successfully'
                    }
                    $script:SuccessCount++
                }
            }
            catch {
                Write-Error "  [FAILED] Could not create computer '$computerName': $_"
                $script:Results += [PSCustomObject]@{
                    ComputerName = $computerName
                    Status       = 'Failed'
                    Reason       = $_.Exception.Message
                }
                $script:FailureCount++
            }
        }
    }
    catch {
        Write-Error "Failed to import or process CSV file: $_"
        exit 1
    }
}

end {
    # Display summary
    Write-Host "`n========== SUMMARY ==========" -ForegroundColor Cyan
    Write-Host "Total processed: $($script:SuccessCount + $script:FailureCount)" -ForegroundColor White
    Write-Host "Successfully created: $script:SuccessCount" -ForegroundColor Green
    Write-Host "Failed/Skipped: $script:FailureCount" -ForegroundColor Yellow
    Write-Host "============================`n" -ForegroundColor Cyan

    # Export results if there are any failures
    if ($script:FailureCount -gt 0) {
        $resultPath = Join-Path -Path (Split-Path $CsvPath) -ChildPath "ComputerCreation_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $script:Results | Export-Csv -Path $resultPath -NoTypeInformation
        Write-Host "Detailed results exported to: $resultPath" -ForegroundColor Yellow
    }
}
