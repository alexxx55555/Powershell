Add-Type -AssemblyName Microsoft.VisualBasic
Import-Module ActiveDirectory

# --- Import Exchange Module (Remote PowerShell) ---
try {
    $s = New-PSSession -ConfigurationName Microsoft.Exchange `
                       -ConnectionUri "http://EX2019/powershell/" `
                       -Authentication Kerberos
    Import-PSSession -Session $s -AllowClobber -DisableNameChecking | Out-Null
    Write-Host "Exchange cmdlets imported successfully." -ForegroundColor Green
} catch {
    Write-Host "Could not import Exchange cmdlets: $_" -ForegroundColor Yellow
}

# ======= CONFIGURATION =======
$ProtectedAccounts = @("Administrator", "krbtgt", "svc_admin", "ITRobot")
$TargetOU      = "OU=Leavers,OU=Alex,DC=alex,DC=local"
$LogDir        = "C:\Temp"
$DateStr       = Get-Date -Format 'yyyyMMdd_HHmmss'
$LogFile       = Join-Path $LogDir "Offboarding_$DateStr.log"
$AuditCsv      = Join-Path $LogDir "OffboardingAudit_$DateStr.csv"
$MailFrom      = "ITRobot@alex.com"
$MailTo        = "ITRobot@alex.com"
$SmtpServer    = "EX2019"

if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType Directory | Out-Null }
$AuditResults = @()

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$date [$Level] $Message"
    Add-Content -Path $LogFile -Value $logMessage
    if     ($Level -eq "ERROR")   { Write-Host $logMessage -ForegroundColor Red }
    elseif ($Level -eq "WARN")    { Write-Host $logMessage -ForegroundColor Yellow }
    elseif ($Level -eq "SUCCESS") { Write-Host $logMessage -ForegroundColor Green }
    else                          { Write-Host $logMessage }
}

function Generate-RandomPassword {
    param([int]$Length = 18)
    Add-Type -AssemblyName System.Web
    [System.Web.Security.Membership]::GeneratePassword($Length,3)
}

function Hide-FromAddressList {
    param($User)
    try {
        Set-ADUser -Identity $User -Replace @{msExchHideFromAddressLists=$true}
        Write-Log "Set msExchHideFromAddressLists for $($User.SamAccountName)" "SUCCESS"
        return $true
    } catch {
        Write-Log "Could not set msExchHideFromAddressLists: $_" "WARN"
        return $false
    }
}

function Archive-Mailbox {
    param($SamAccountName)
    # Check if Exchange cmdlets are available before running
    if (-not (Get-Command Get-Mailbox -ErrorAction SilentlyContinue)) {
        Write-Log "EXCHANGE WARNING: Exchange cmdlets not loaded, skipping mailbox archive for ${SamAccountName}. Please run in Exchange Management Shell or import Exchange session." "WARN"
        [System.Windows.Forms.MessageBox]::Show(
            "Exchange cmdlets not loaded. Mailbox archive will be skipped for user ${SamAccountName}.",
            "Exchange Not Available", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return "Skipped"
    }
    try {
        $mbx = Get-Mailbox -Identity $SamAccountName -ErrorAction Stop
        if ($mbx.ArchiveStatus -eq "None") {
            Enable-Mailbox -Identity $SamAccountName -Archive
            Write-Log "Archive mailbox ENABLED for ${SamAccountName}" "SUCCESS"
            return "Enabled"
        } else {
            Write-Log "Mailbox archive ALREADY ENABLED for ${SamAccountName}" "SUCCESS"
            return "AlreadyEnabled"
        }
    } catch {
        Write-Log "Could not archive mailbox for ${SamAccountName}: $_" "WARN"
        return "Failed"
    }
}

function Offboard-User {
    param($user)

    if ($ProtectedAccounts -contains $user.SamAccountName) {
        Write-Log "SKIPPED protected account: $($user.SamAccountName)" "WARN"
        return
    }

    $beforeGroups = @()
    $afterGroups  = @()
    $actions = @()
    $failedActions = @()
    $desc = "Leaver $(Get-Date -Format yyyy-MM-dd)"
    $randomPW = Generate-RandomPassword
    $mailSent = ""
    $archiveStatus = ""

    # 1. Export current group membership
    $beforeGroups = (Get-ADUser $user -Properties MemberOf | Select-Object -ExpandProperty MemberOf | ForEach-Object { (Get-ADGroup $_).Name }) -join "; "

    # 2. Reset password to random **BEFORE disabling**
    try {
        Set-ADAccountPassword -Identity $user -NewPassword (ConvertTo-SecureString $randomPW -AsPlainText -Force) -Reset -ErrorAction Stop
        Write-Log "Password reset for $($user.SamAccountName). New password: $randomPW" "SUCCESS"
        $actions += "PWReset"
    } catch {
        Write-Log "FAILED to reset password: $_" "WARN"
        $failedActions += "PWReset"
    }

    # 3. Disable account
    try {
        Disable-ADAccount -Identity $user -ErrorAction Stop
        Write-Log "Disabled: $($user.SamAccountName)" "SUCCESS"
        $actions += "Disabled"
    } catch {
        Write-Log "FAILED to disable: $_" "ERROR"
        $failedActions += "Disable"
    }

    # 4. Remove from all groups except Domain Users
    $groups = Get-ADUser $user -Properties MemberOf | Select-Object -ExpandProperty MemberOf
    foreach ($groupDN in $groups) {
        $group = Get-ADGroup -Identity $groupDN
        if ($group.Name -ne "Domain Users") {
            try {
                Remove-ADGroupMember -Identity $group -Members $user -Confirm:$false
                Write-Log "Removed $($user.SamAccountName) from group $($group.Name)" "SUCCESS"
                $actions += "Removed from $($group.Name)"
            } catch {
                Write-Log "FAILED to remove $($user.SamAccountName) from $($group.Name): $_" "WARN"
                $failedActions += "Group:$($group.Name)"
            }
        }
    }

    # 5. Move to Leavers OU
    try {
        Move-ADObject -Identity $user.DistinguishedName -TargetPath ${TargetOU} -ErrorAction Stop
        Write-Log "Moved to OU: ${TargetOU}" "SUCCESS"
        $actions += "MovedOU"
    } catch {
        Write-Log "FAILED to move to ${TargetOU}: $_" "WARN"
        $failedActions += "MoveOU"
    }

    # After moving, re-query user for further actions (may have new DN/context)
    try {
        $user = Get-ADUser -Identity $user.SamAccountName -Properties MemberOf,DistinguishedName,Enabled,Name
    } catch {
        Write-Log "FAILED to re-query user after move: $_" "WARN"
    }

    # 6. Update description
    try {
        Set-ADUser -Identity $user -Description $desc
        Write-Log "Description updated: $desc" "SUCCESS"
        $actions += "Desc"
    } catch {
        Write-Log "FAILED to set description: $_" "WARN"
        $failedActions += "Desc"
    }

    # 7. Hide from Exchange Address List (optional)
    try { Hide-FromAddressList $user | Out-Null } catch {}

    # 8. ARCHIVE MAILBOX (EXCHANGE)
    try { $archiveStatus = Archive-Mailbox $user.SamAccountName } catch { $archiveStatus = "Failed" }

    # 9. Export after-action group membership
    try {
        $afterGroups = (Get-ADUser $user -Properties MemberOf | Select-Object -ExpandProperty MemberOf | ForEach-Object { (Get-ADGroup $_).Name }) -join "; "
    } catch {
        $afterGroups = ""
        Write-Log "Could not get after-action group membership: $_" "WARN"
    }

    # 10. Notify IT and manager
    $managerEmail = ""
    try {
        $managerDN = (Get-ADUser $user -Properties Manager).Manager
        if ($managerDN) {
            $managerObj = Get-ADUser -Identity $managerDN -Properties EmailAddress
            if ($managerObj.EmailAddress) { $managerEmail = $managerObj.EmailAddress }
        }
    } catch { $managerEmail = "" }

    $subject = "User OFFBOARDED: $($user.Name) ($($user.SamAccountName))"
    $body = @"
User $($user.Name) ($($user.SamAccountName)) has been offboarded:

- Disabled in AD
- Removed from most groups
- Moved to: ${TargetOU}
- Password reset: $randomPW
- Description: $desc
- Hidden from address book: Yes
- Mailbox archive status: $archiveStatus

Actions: $($actions -join ', ')
Failed actions: $($failedActions -join ', ')

Offboarded: $(Get-Date -Format u)
"@

    # Email manager
    if ($managerEmail) {
        try {
            Send-MailMessage -To $managerEmail -From $MailFrom -Subject $subject -Body $body -SmtpServer $SmtpServer
            Write-Log "Offboarding email sent to MANAGER $managerEmail" "SUCCESS"
        } catch {
            Write-Log "FAILED to email manager: $_" "WARN"
        }
    } else {
        Write-Log "Manager email not found (user may have no manager assigned)" "WARN"
    }
    # Email ITRobot (always)
    try {
        Send-MailMessage -To $MailTo -From $MailFrom -Subject $subject -Body $body -SmtpServer $SmtpServer
        Write-Log "Offboarding email sent to $MailTo" "SUCCESS"
        $mailSent = "Yes"
    } catch {
        Write-Log "FAILED to send IT notification: $_" "WARN"
        $mailSent = "No"
    }

    # 11. Export audit row
    $AuditResults += [PSCustomObject]@{
        SamAccountName  = $user.SamAccountName
        Name            = $user.Name
        Offboarded      = Get-Date
        Disabled        = $true
        MovedToOU       = $TargetOU
        OldGroups       = $beforeGroups
        NewGroups       = $afterGroups
        PWReset         = $randomPW
        Description     = $desc
        Actions         = $actions -join '; '
        FailedActions   = $failedActions -join '; '
        MailSent        = $mailSent
        ArchiveMailbox  = $archiveStatus
        ManagerEmail    = $managerEmail
    }
}

# ==== GUI Prompt: just "Enter name for offboarding" ====
$InputValue = [Microsoft.VisualBasic.Interaction]::InputBox(
    "",  # blank message
    "Enter name for offboarding"
)
if (-not $InputValue) {
    Write-Log "No username/full name entered, exiting." "ERROR"
    exit
}

# Try SamAccountName first
$user = $null
try {
    $user = Get-ADUser -Identity $InputValue -Properties MemberOf,DistinguishedName,Enabled,Name
} catch {}

# If not found by SamAccountName, search by full name (may return multiple!)
if (-not $user) {
    $matched = Get-ADUser -Filter {Name -eq $InputValue} -Properties MemberOf,DistinguishedName,Enabled,Name
    if ($matched.Count -eq 1) {
        $user = $matched
    } elseif ($matched.Count -gt 1) {
        Write-Log "Multiple users found for Name='$InputValue'. Offboarding the first: $($matched[0].SamAccountName)" "WARN"
        $user = $matched[0]
    } else {
        Write-Log "User not found with username or full name: $InputValue" "ERROR"
        exit
    }
}

Offboard-User $user

# Export the results for audit
$AuditResults | Export-Csv -Path $AuditCsv -NoTypeInformation
Write-Log "Audit results exported to $AuditCsv" "SUCCESS"
