#Requires -RunAsAdministrator
# ============================================================
# Inactive AD Users Check & Auto-Disable
# Runs weekly via n8n Schedule Trigger
# Scans OU=Users,OU=Alex,DC=alex,DC=local for 30+ day inactive users
# ============================================================

$WebhookUrl = 'https://n8n.pi.alex-it.net/webhook/inactive-users-report'
$SharedSecret = 'n8w-GmC9x$kQ2vLpR7fT4bYe!Aj6Xs8Z'
$SearchBase = 'OU=Users,OU=Alex,DC=alex,DC=local'
$DisabledOU = 'OU=Disabled Users,OU=Alex,DC=alex,DC=local'
$InactiveDays = 30
$CutoffDate = (Get-Date).AddDays(-$InactiveDays)

# Service accounts to exclude from disable/move
$ExcludeUsers = @('ITrobot')

try {
    # Filter out already-processed events and sort oldest first — also exclude service accounts
    $InactiveUsers = Get-ADUser -SearchBase $SearchBase -Filter {
        Enabled -eq $true -and LastLogonDate -lt $CutoffDate
    } -Properties LastLogonDate, DisplayName, Description, WhenCreated |
    Where-Object { $ExcludeUsers -notcontains $_.SamAccountName } |
    Sort-Object LastLogonDate

    # Also find enabled users who have NEVER logged in
    $NeverLoggedIn = Get-ADUser -SearchBase $SearchBase -Filter {
        Enabled -eq $true -and LastLogonDate -notlike "*"
    } -Properties LastLogonDate, DisplayName, Description, WhenCreated |
    Where-Object { $_.WhenCreated -lt $CutoffDate -and $ExcludeUsers -notcontains $_.SamAccountName } |
    Sort-Object WhenCreated

    # Combine both lists
    $AllInactive = @()

    foreach ($User in $InactiveUsers) {
        # Disable the account
        Disable-ADAccount -Identity $User.SamAccountName -ErrorAction Stop
        # Move to Disabled Users OU
        Move-ADObject -Identity $User.DistinguishedName -TargetPath $DisabledOU -ErrorAction Stop

        $AllInactive += @{
            samAccountName = $User.SamAccountName
            displayName    = if ($User.DisplayName) { $User.DisplayName } else { $User.Name }
            lastLogon      = if ($User.LastLogonDate) { $User.LastLogonDate.ToString('dd/MM/yyyy') } else { 'Never' }
            daysSinceLogon = if ($User.LastLogonDate) { [math]::Round(((Get-Date) - $User.LastLogonDate).TotalDays) } else { 'N/A' }
            description    = if ($User.Description) { $User.Description } else { '' }
            disabled       = $true
            error          = ''
        }
    }

    foreach ($User in $NeverLoggedIn) {
        # Disable the account
        Disable-ADAccount -Identity $User.SamAccountName -ErrorAction Stop
        # Move to Disabled Users OU
        Move-ADObject -Identity $User.DistinguishedName -TargetPath $DisabledOU -ErrorAction Stop

        $AllInactive += @{
            samAccountName = $User.SamAccountName
            displayName    = if ($User.DisplayName) { $User.DisplayName } else { $User.Name }
            lastLogon      = 'Never'
            daysSinceLogon = [math]::Round(((Get-Date) - $User.WhenCreated).TotalDays)
            description    = if ($User.Description) { $User.Description } else { '' }
            disabled       = $true
            error          = ''
        }
    }

    # Build the payload
    $Payload = @{
        secret         = $SharedSecret
        totalInactive  = $AllInactive.Count
        inactiveUsers  = $AllInactive
        scanDate       = (Get-Date).ToString('dd/MM/yyyy hh:mm tt')
        searchBase     = $SearchBase
        inactiveDays   = $InactiveDays
        dcName         = $env:COMPUTERNAME
    }

    $Body = $Payload | ConvertTo-Json -Depth 5

    # Send to n8n webhook
    Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $Body -ContentType 'application/json' -TimeoutSec 30

    Write-EventLog -LogName Application -Source 'ADGroupMonitor' -EventId 2000 -EntryType Information -Message "Inactive users report sent. Found and disabled $($AllInactive.Count) inactive users."

} catch {
    Write-EventLog -LogName Application -Source 'ADGroupMonitor' -EventId 2001 -EntryType Error -Message "Failed to process inactive users report: $_"
}