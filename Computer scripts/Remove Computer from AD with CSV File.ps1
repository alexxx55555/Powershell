<#
.SYNOPSIS
    Removes computer objects from Active Directory based on a CSV file.

.DESCRIPTION
    This script imports computer information from a CSV file and removes the corresponding computer objects from Active Directory.
    The CSV file must contain a column with computer names (Name, SamAccountName, or DNSHostName).

    CAUTION: This script permanently removes computer accounts. Use -WhatIf to preview actions before executing.

.PARAMETER CsvPath
    The path to the CSV file containing computer information to remove.
    Default: C:\AD User\computers.csv

.PARAMETER ComputerNameColumn
    The name of the CSV column containing the computer identifiers.
    Default: SamAccountName

.PARAMETER Confirm
    Prompts for confirmation before removing each computer.
    Default: $false (no confirmation)

.PARAMETER WhatIf
    Shows what computers would be removed without actually removing them.

.EXAMPLE
    .\Remove Computer from AD with CSV File.ps1 -WhatIf
    Shows what computers would be removed without actually removing them.

.EXAMPLE
    .\Remove Computer from AD with CSV File.ps1 -CsvPath "C:\Temp\oldcomps.csv"
    Removes computers listed in the specified CSV file.

.EXAMPLE
    .\Remove Computer from AD with CSV File.ps1 -Confirm:$true
    Prompts for confirmation before removing each computer.

.NOTES
    Author: IT Department
    Requires: ActiveDirectory module
    WARNING: This script permanently deletes computer accounts!
    CSV Format Example:
        SamAccountName
        OLDPC01
        OLDPC02
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false)]
    [ValidateScript({
        if (Test-Path $_ -PathType Leaf) { $true }
        else { throw "CSV file not found: $_" }
    })]
    [string]$CsvPath = 'C:\AD User\computers.csv',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ComputerNameColumn = 'SamAccountName'
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
    $script:NotFoundCount = 0
    $script:Results = @()

    Write-Warning "This script will PERMANENTLY REMOVE computer accounts from Active Directory!"
    Write-Host "Use -WhatIf to preview actions without making changes" -ForegroundColor Yellow
}

process {
    try {
        # Import CSV file
        Write-Host "`nImporting computer data from: $CsvPath" -ForegroundColor Cyan
        $computers = Import-Csv -Path $CsvPath -ErrorAction Stop

        if ($computers.Count -eq 0) {
            Write-Warning "No computers found in CSV file"
            return
        }

        Write-Host "Found $($computers.Count) computer(s) to process`n" -ForegroundColor Green

        # Validate that the specified column exists
        $firstRow = $computers[0]
        if (-not $firstRow.PSObject.Properties.Name -contains $ComputerNameColumn) {
            throw "Column '$ComputerNameColumn' not found in CSV. Available columns: $($firstRow.PSObject.Properties.Name -join ', ')"
        }

        # Process each computer
        foreach ($computer in $computers) {
            $computerName = $computer.$ComputerNameColumn

            if ([string]::IsNullOrWhiteSpace($computerName)) {
                Write-Warning "Skipping row with empty $ComputerNameColumn"
                $script:FailureCount++
                continue
            }

            try {
                # Check if computer exists
                $adComputer = Get-ADComputer -Filter "SamAccountName -eq '$computerName' -or Name -eq '$computerName'" -ErrorAction SilentlyContinue

                if (-not $adComputer) {
                    Write-Warning "Computer '$computerName' not found in Active Directory - skipping"
                    $script:Results += [PSCustomObject]@{
                        ComputerName = $computerName
                        Status       = 'Not Found'
                        Reason       = 'Does not exist in AD'
                        Timestamp    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    }
                    $script:NotFoundCount++
                    continue
                }

                # Remove the computer
                if ($PSCmdlet.ShouldProcess($adComputer.Name, "Remove computer from Active Directory")) {
                    Remove-ADComputer -Identity $adComputer -Confirm:$false -ErrorAction Stop
                    Write-Host "  [REMOVED] $($adComputer.Name)" -ForegroundColor Red
                    $script:Results += [PSCustomObject]@{
                        ComputerName = $adComputer.Name
                        Status       = 'Removed'
                        Reason       = 'Successfully deleted'
                        Timestamp    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    }
                    $script:SuccessCount++
                }
            }
            catch {
                Write-Error "  [FAILED] Could not remove computer '$computerName': $_"
                $script:Results += [PSCustomObject]@{
                    ComputerName = $computerName
                    Status       = 'Failed'
                    Reason       = $_.Exception.Message
                    Timestamp    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
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
    Write-Host "Total processed: $($script:SuccessCount + $script:FailureCount + $script:NotFoundCount)" -ForegroundColor White
    Write-Host "Successfully removed: $script:SuccessCount" -ForegroundColor Red
    Write-Host "Not found in AD: $script:NotFoundCount" -ForegroundColor Yellow
    Write-Host "Failed: $script:FailureCount" -ForegroundColor Yellow
    Write-Host "============================`n" -ForegroundColor Cyan

    # Always export results log
    $resultPath = Join-Path -Path (Split-Path $CsvPath) -ChildPath "ComputerRemoval_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $script:Results | Export-Csv -Path $resultPath -NoTypeInformation
    Write-Host "Detailed results exported to: $resultPath" -ForegroundColor Cyan
}
