Add-Type -AssemblyName System.Windows.Forms
Import-Module ActiveDirectory

# --- CONFIGURATION ---
$OU = "OU=Users,OU=Alex,DC=alex,DC=local"
$LogDir = "C:\Temp"
$DateStr = Get-Date -Format 'yyyyMMdd_HHmmss'
$LogFile = Join-Path $LogDir "EnableADUsers_$DateStr.log"
$CsvFile = Join-Path $LogDir "EnableADUsersResults_$DateStr.csv"

# --- EMAIL CONFIG ---
$MailFrom      = "ITRobot@alex.com"
$MailSubject   = "Your account has been enabled"
$SmtpServer    = "EX2019"
$MailBodyTemplate = @"
Hello {0},

Your Active Directory account has been enabled.

If you have any questions or need help, please contact IT.

Thank you,
Alex IT
"@

# --- INITIALIZATION ---
if (!(Test-Path -Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory | Out-Null }
$Script:LogFile = $LogFile
$ExportResults = @()
$usersFromCsv = @()

# --- FUNCTIONS ---
function Write-Log {
    param([string]$Message, [string]$Level = "Info")
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$date [$Level] $Message"
    Add-Content -Path $Script:LogFile -Value $logMessage
    # Color output
    switch ($Level) {
        "Success" { Write-Host $logMessage -ForegroundColor Green }
        "Error"   { Write-Host $logMessage -ForegroundColor Red }
        "Warning" { Write-Host $logMessage -ForegroundColor Yellow }
        default   { Write-Host $logMessage }
    }
}

function Get-DisabledUsersInOU($OU) {
    return Get-ADUser -SearchBase $OU -Filter {Enabled -eq $false}
}

function Enable-UserAccount {
    param(
        [Parameter(Mandatory=$true)]$User,
        [Parameter(Mandatory=$true)]$Password,
        [Parameter()]$RequireChangeAtLogon = $true
    )
    try {
        Set-ADAccountPassword -Identity $User -NewPassword $Password -Reset
        Enable-ADAccount -Identity $User
        if ($RequireChangeAtLogon) {
            Set-ADUser -Identity $User -ChangePasswordAtLogon $true
        }
        Write-Log "Enabled: $($User.SamAccountName)" "Success"
        return $true
    }
    catch {
        Write-Log "FAILED to enable $($User.SamAccountName): $_" "Error"
        return $false
    }
}

function Send-EnableNotification {
    param(
        [Parameter(Mandatory=$true)]$User,
        [Parameter(Mandatory=$false)]$ManagerEmail
    )
    try {
        $email = $User.EmailAddress
        if (-not $email) { return "NoUserEmail" }
        $body = [string]::Format($MailBodyTemplate, $User.Name)
        if ($ManagerEmail) {
            Send-MailMessage -To $email -Cc $ManagerEmail -From $MailFrom -Subject $MailSubject -Body $body -SmtpServer $SmtpServer
        } else {
            Send-MailMessage -To $email -From $MailFrom -Subject $MailSubject -Body $body -SmtpServer $SmtpServer
        }
        Write-Log "Enable notification sent to $($User.SamAccountName) <$email>, CC: $ManagerEmail" "Success"
        return "Notified"
    } catch {
        Write-Log "FAILED to send enable notification to $($User.SamAccountName): $_" "Error"
        return "NotifyFailed"
    }
}

function Show-Summary {
    param($enabledCount, $skippedCount, $failedCount)
    $summary = "Summary:`nEnabled: $enabledCount`nSkipped: $skippedCount`nFailed: $failedCount`n`nLog file: $Script:LogFile"
    [System.Windows.Forms.MessageBox]::Show($summary, "Summary", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Import-UsersFromCsv {
    param([string]$Path)
    if (!(Test-Path $Path)) {
        Write-Log "CSV file $Path not found." "Error"
        return @()
    }
    try {
        $csv = Import-Csv $Path
        Write-Log "Imported $($csv.Count) users from CSV: $Path" "Success"
        return $csv
    }
    catch {
        Write-Log "Error importing CSV: $_" "Error"
        return @()
    }
}

# --- MAIN SCRIPT ---

# Prompt for CSV import option
$useCsv = $false
$csvPath = ""
$csvPrompt = [System.Windows.Forms.MessageBox]::Show(
    "Do you want to enable users from a CSV file instead of the whole OU?",
    "CSV User Import",
    [System.Windows.Forms.MessageBoxButtons]::YesNo,
    [System.Windows.Forms.MessageBoxIcon]::Question
)
if ($csvPrompt -eq [System.Windows.Forms.DialogResult]::Yes) {
    $useCsv = $true
    $csvPath = [System.Windows.Forms.OpenFileDialog]::new()
    $csvPath.Filter = "CSV files (*.csv)|*.csv"
    $csvPath.Title = "Select CSV file"
    if ($csvPath.ShowDialog() -eq "OK") {
        $usersFromCsv = Import-UsersFromCsv $csvPath.FileName
        if ($usersFromCsv.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No users loaded from CSV. Exiting.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("CSV file not selected. Exiting.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
}

# Prompt for password (used if CSV does NOT provide per-user password)
$password = Read-Host "Enter a new password to set for enabled users (or leave blank to use per-user from CSV)" -AsSecureString

# Get disabled users
if ($useCsv) {
    $disabledUsers = @()
    foreach ($entry in $usersFromCsv) {
        $user = Get-ADUser -Filter {SamAccountName -eq $($entry.SamAccountName)} -SearchBase $OU
        if ($user -and $user.Enabled -eq $false) {
            $user | Add-Member -MemberType NoteProperty -Name 'CsvPassword' -Value $entry.Password -Force
            $disabledUsers += $user
        } elseif ($user -and $user.Enabled -eq $true) {
            Write-Log "User $($entry.SamAccountName) is already enabled. Skipping." "Warning"
        } else {
            Write-Log "User $($entry.SamAccountName) not found in OU. Skipping." "Warning"
        }
    }
} else {
    $disabledUsers = Get-DisabledUsersInOU $OU
}

if (!$disabledUsers -or $disabledUsers.Count -eq 0) {
    [System.Windows.Forms.MessageBox]::Show("No disabled users found in your selection.", "Info", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    Write-Log "No disabled users found in your selection."
    return
}

[int]$enabledCount = 0
[int]$skippedCount = 0
[int]$failedCount = 0

foreach ($user in $disabledUsers) {
    $uPass = $null
    # Use per-user password from CSV if available, otherwise prompt password
    if ($useCsv -and $user.PSObject.Properties['CsvPassword'] -and $user.CsvPassword) {
        $uPass = ConvertTo-SecureString $user.CsvPassword -AsPlainText -Force
    } else {
        $uPass = $password
    }

    $message = "Enable user $($user.SamAccountName) ($($user.Name))?"
    if ($useCsv -and $user.PSObject.Properties['CsvPassword'] -and $user.CsvPassword) {
        $message += "`n(Password: [per-user from CSV])"
    }
    $caption = "Enable User"
    $result = [System.Windows.Forms.MessageBox]::Show($message, $caption, [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)
    $status = ""
    $notifyStatus = ""
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        if (Enable-UserAccount -User $user -Password $uPass) {
            $enabledCount++
            $status = "Enabled"

            # Find manager's email if present
            $managerEmail = $null
            $userObj = Get-ADUser -Identity $user -Properties EmailAddress,Manager,Name
            if ($userObj.Manager) {
                $managerObj = Get-ADUser -Identity $userObj.Manager -Properties EmailAddress
                if ($managerObj.EmailAddress) {
                    $managerEmail = $managerObj.EmailAddress
                }
            }
            $notifyStatus = Send-EnableNotification -User $userObj -ManagerEmail $managerEmail
        } else {
            $failedCount++
            $status = "Failed"
            $notifyStatus = ""
        }
    } else {
        Write-Log "Skipped: $($user.SamAccountName)" "Warning"
        $skippedCount++
        $status = "Skipped"
        $notifyStatus = ""
    }
    # Add to export results
    $ExportResults += [PSCustomObject]@{
        SamAccountName = $user.SamAccountName
        Name = $user.Name
        Status = $status
        Notification = $notifyStatus
        DateTime = Get-Date
    }
}

Show-Summary $enabledCount $skippedCount $failedCount

$ExportResults | Export-Csv -Path $CsvFile -NoTypeInformation
Write-Log "Results exported to $CsvFile" "Info"
Write-Log "Script complete. Summary: Enabled: $enabledCount, Skipped: $skippedCount, Failed: $failedCount" "Info"
