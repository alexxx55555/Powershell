#Requires -RunAsAdministrator
# ============================================================
# AD Group Membership Change Monitor
# Deploy on each Domain Controller as a Scheduled Task
# Trigger: On Event - Security Log - Event IDs 4728,4729,4732,4733,4756,4757
# ============================================================

$WebhookUrl = 'https://n8n.pi.alex-it.net/webhook/group-membership-change'
$SharedSecret = 'n8w-GmC9x$kQ2vLpR7fT4bYe!Aj6Xs8Z'
$LockFile = 'C:\Scripts\last_event.txt'
$MutexName = 'Global\ADGroupMonitorMutex'

# Event IDs to monitor
$EventIDs = @(4728, 4729, 4732, 4733, 4756, 4757)
$AddEvents = @(4728, 4732, 4756)
$RemoveEvents = @(4729, 4733, 4757)

# Use a mutex to prevent concurrent runs from overlapping
$Mutex = New-Object System.Threading.Mutex($false, $MutexName)
try {
    $Mutex.WaitOne(10000) | Out-Null

    # Small delay to let the event fully write to the log
    Start-Sleep -Milliseconds 800

    # Read last processed event record ID
    $LastRecordId = 0
    if (Test-Path $LockFile) {
        $LastRecordId = [long](Get-Content $LockFile -ErrorAction SilentlyContinue)
    }

    # Get recent matching events
    $Events = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        Id      = $EventIDs
    } -MaxEvents 10 -ErrorAction Stop

    # Filter out already-processed events and sort oldest first
    $NewEvents = $Events | Where-Object { $_.RecordId -gt $LastRecordId } | Sort-Object RecordId

    if (-not $NewEvents -or $NewEvents.Count -eq 0) {
        exit 0
    }

    # Process each new event in chronological order
    foreach ($Event in $NewEvents) {

        # Parse the event XML
        [xml]$EventXml = $Event.ToXml()
        $Data = @{}
        foreach ($d in $EventXml.Event.EventData.Data) {
            $Data[$d.Name] = $d.'#text'
        }

        # Determine action type
        if ($AddEvents -contains $Event.Id) {
            $ActionType = 'MEMBER_ADDED'
        } elseif ($RemoveEvents -contains $Event.Id) {
            $ActionType = 'MEMBER_REMOVED'
        } else {
            $ActionType = 'UNKNOWN'
        }

        # Resolve the affected user SID to a name and get display name
        $AffectedUser = 'Unknown'
        $AffectedDisplayName = ''
        if ($Data['MemberSid']) {
            try {
                $SID = New-Object System.Security.Principal.SecurityIdentifier($Data['MemberSid'])
                $AffectedUser = $SID.Translate([System.Security.Principal.NTAccount]).Value
                # Look up the full display name from AD
                $ADUser = Get-ADUser -Identity $SID -Properties DisplayName -ErrorAction Stop
                if ($ADUser.DisplayName) {
                    $AffectedDisplayName = $ADUser.DisplayName
                }
            } catch {
                $AffectedUser = $Data['MemberSid']
            }
        }

        # Build the performed by string and get display name
        $PerformedBy = '{0}\{1}' -f $Data['SubjectDomainName'], $Data['SubjectUserName']
        $PerformedByDisplayName = ''
        try {
            $ADPerformer = Get-ADUser -Identity $Data['SubjectUserName'] -Properties DisplayName -ErrorAction Stop
            if ($ADPerformer.DisplayName) {
                $PerformedByDisplayName = $ADPerformer.DisplayName
            }
        } catch {
            $PerformedByDisplayName = ''
        }

        # Build the payload
        $Payload = @{
            secret           = $SharedSecret
            actionType       = $ActionType
            affectedUser     = $AffectedUser
            affectedDisplayName = $AffectedDisplayName
            groupName        = $Data['TargetUserName']
            groupDomain      = $Data['TargetDomainName']
            performedBy      = $PerformedBy
            performedByDisplayName = $PerformedByDisplayName
            eventId          = [int]$Event.Id
            timestamp        = $Event.TimeCreated.ToString('yyyy-MM-ddTHH:mm:ssZ')
            dcName           = $env:COMPUTERNAME
            autoDisabled     = $false
            autoDisableError = ''
        }

        $Body = $Payload | ConvertTo-Json -Depth 3

        # Send to n8n webhook
        Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $Body -ContentType 'application/json' -TimeoutSec 10

        # Update the lock file after each successful send
        $Event.RecordId | Out-File -FilePath $LockFile -Force

        Write-EventLog -LogName Application -Source 'ADGroupMonitor' -EventId 1000 -EntryType Information -Message "Sent alert: $ActionType for $($Data['TargetUserName']) (RecordId: $($Event.RecordId))"
    }

} catch {
    Write-EventLog -LogName Application -Source 'ADGroupMonitor' -EventId 1001 -EntryType Error -Message "Failed to process group membership event: $_"
} finally {
    $Mutex.ReleaseMutex()
    $Mutex.Dispose()
}