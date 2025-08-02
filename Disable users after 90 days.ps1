Import-Module ActiveDirectory

# ======= CONFIGURATION =======
$OU            = "OU=Users,OU=Alex,DC=alex,DC=local"
$daysInactive  = 90
$LogDir        = "C:\Temp"
$DateStr       = Get-Date -Format 'yyyyMMdd_HHmmss'
$LogFile       = Join-Path $LogDir "DisableAndWarnInactiveUsers_$DateStr.log"
$CsvFile       = Join-Path $LogDir "DisableAndWarnInactiveUsersResults_$DateStr.csv"
$exclude       = @("ITRobot")   # List accounts you NEVER want to disable or notify

# Email config
$MailFrom      = "ITRobot@alex.com"
$MailSubject   = "Your account has been disabled"
$SmtpServer    = "EX2019"
$MailBodyTemplate = @"
Hello {0},

Your user account has been disabled due to inactivity or policy.
If you believe this is an error or need your account re-enabled, please contact IT Support.

Thank you,
Alex IT
"@

if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory | Out-Null }
$ExportResults = @()
$Total = 0; $Disabled = 0; $Failed = 0; $Notified = 0; $NotifyFailed = 0

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$date [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage
    if     ($Level -eq "ERROR")   { Write-Host $logMessage -ForegroundColor Red }
    elseif ($Level -eq "SUCCESS") { Write-Host $logMessage -ForegroundColor Yellow }
    elseif ($Level -eq "NOTIFY")  { Write-Host $logMessage -ForegroundColor Green }
    else  { Write-Host $logMessage }
}

function Disable-UserAccount {
    param($User)
    try {
        Disable-ADAccount -Identity $User -ErrorAction Stop
        Write-Log "Disabled: $($User.SamAccountName)" "SUCCESS"
        return "Disabled"
    } catch {
        Write-Log "FAILED to disable $($User.SamAccountName): $_" "ERROR"
        return "Failed"
    }
}

function Send-WarningEmail {
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
        Write-Log "Notified $($User.SamAccountName) <$email>, CC: $ManagerEmail" "NOTIFY"
        return "Notified"
    } catch {
        Write-Log "FAILED to send notification to $($User.SamAccountName): $_" "ERROR"
        return "NotifyFailed"
    }
}

# ======= MAIN LOGIC =======
$time = (Get-Date).AddDays(-$daysInactive)

# Get all enabled users in the OU (with LastLogonDate property)
$allEnabledUsers = Get-ADUser -SearchBase $OU -Filter {Enabled -eq $true} -Properties LastLogonDate,EmailAddress,Manager,Name

# Filter users who haven't logged in for $daysInactive+ days OR never logged in
$usersToDisable = $allEnabledUsers | Where-Object {
    ((-not $_.LastLogonDate) -or ($_.LastLogonDate -lt $time)) -and ($exclude -notcontains $_.SamAccountName)
}

if (!$usersToDisable -or $usersToDisable.Count -eq 0) {
    Write-Log "No enabled users in $OU inactive for $daysInactive+ days (or never logged in, or all excluded)." "INFO"
    return
}

foreach ($user in $usersToDisable) {
    $Total++
    $status = Disable-UserAccount $user
    if ($status -eq "Disabled") {
        $Disabled++
        # --- Email to user and manager ---
        $managerEmail = $null
        if ($user.Manager) {
            $manager = Get-ADUser -Identity $user.Manager -Properties EmailAddress
            if ($manager.EmailAddress) {
                $managerEmail = $manager.EmailAddress
            }
        }
        $notifyStatus = Send-WarningEmail -User $user -ManagerEmail $managerEmail
        if ($notifyStatus -eq "Notified") { $Notified++ } elseif ($notifyStatus -eq "NotifyFailed") { $NotifyFailed++ }
        $ExportResults += [PSCustomObject]@{
            SamAccountName = $user.SamAccountName
            Name           = $user.Name
            LastLogonDate  = $user.LastLogonDate
            Status         = $status
            Notification   = $notifyStatus
            ManagerEmail   = $managerEmail
            DateTime       = Get-Date
        }
    } else {
        $Failed++
        $ExportResults += [PSCustomObject]@{
            SamAccountName = $user.SamAccountName
            Name           = $user.Name
            LastLogonDate  = $user.LastLogonDate
            Status         = $status
            Notification   = ""
            ManagerEmail   = ""
            DateTime       = Get-Date
        }
    }
}

$ExportResults | Export-Csv -Path $CsvFile -NoTypeInformation
Write-Log "Results exported to $CsvFile" "INFO"
Write-Log "Summary: Total processed: $Total, Disabled: $Disabled, Failed: $Failed, Notified: $Notified, NotifyFailed: $NotifyFailed" "INFO"
