#Requires -RunAsAdministrator
# ============================================================
# AD Device Monitor - Created, Disabled, Deleted
# Trigger: On Event - Security Log - Event IDs 4741, 4742, 4743
# ============================================================

$WebhookUrl = 'https://n8n.pi.alex-it.net/webhook/device-change'
$SharedSecret = 'n8w-GmC9x$kQ2vLpR7fT4bYe!Aj6Xs8Z'
$MonitoredOU = 'OU=Workstations,OU=Alex,DC=alex,DC=local'
$LockFile = 'C:\Scripts\last_device_event.txt'
$MutexName = 'Global\ADDeviceMonitorMutex'

$Mutex = New-Object System.Threading.Mutex($false, $MutexName)
try {
    $Mutex.WaitOne(10000) | Out-Null

    Start-Sleep -Milliseconds 800

    # Read last processed event record ID
    $LastRecordId = 0
    if (Test-Path $LockFile) {
        $LastRecordId = [long](Get-Content $LockFile -ErrorAction SilentlyContinue)
    }

    # Get recent device events
    $Events = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        Id      = @(4741, 4742, 4743)
    } -MaxEvents 10 -ErrorAction Stop

    # Filter new events only, oldest first
    $NewEvents = $Events | Where-Object { $_.RecordId -gt $LastRecordId } | Sort-Object RecordId

    if (-not $NewEvents -or $NewEvents.Count -eq 0) {
        exit 0
    }

    foreach ($Event in $NewEvents) {

        # Parse event XML
        [xml]$EventXml = $Event.ToXml()
        $Data = @{}
        foreach ($d in $EventXml.Event.EventData.Data) {
            $Data[$d.Name] = $d.'#text'
        }

        $ComputerName = $Data['TargetUserName'] -replace '\$$', ''
        $PerformedBy = '{0}\{1}' -f $Data['SubjectDomainName'], $Data['SubjectUserName']

        # Get performer display name
        $PerformedByDisplayName = ''
        try {
            $ADPerformer = Get-ADUser -Identity $Data['SubjectUserName'] -Properties DisplayName -ErrorAction Stop
            if ($ADPerformer.DisplayName) {
                $PerformedByDisplayName = $ADPerformer.DisplayName
            }
        } catch {}

        # Determine action type
        $ActionType = ''
        $ShouldAlert = $false

        switch ($Event.Id) {
            4741 {
                # Computer created
                $ActionType = 'DEVICE_CREATED'
                $ComputerObj = $null
                try {
                    $ComputerObj = Get-ADComputer -Identity $ComputerName -Properties OperatingSystem, OperatingSystemVersion, Description, DistinguishedName -ErrorAction Stop
                } catch {}
                if ($ComputerObj -and $ComputerObj.DistinguishedName -like "*$MonitoredOU*") {
                    $ShouldAlert = $true
                }
            }
            4742 {
                # Computer changed — check if it was disabled
                $ComputerObj = $null
                try {
                    $ComputerObj = Get-ADComputer -Identity $ComputerName -Properties Enabled, OperatingSystem, OperatingSystemVersion, Description, DistinguishedName -ErrorAction Stop
                } catch {}
                if ($ComputerObj -and $ComputerObj.Enabled -eq $false) {
                    $ActionType = 'DEVICE_DISABLED'
                    $ShouldAlert = $true
                }
            }
            4743 {
                # Computer deleted
                $ActionType = 'DEVICE_DELETED'
                $ShouldAlert = $true
                $ComputerObj = $null
            }
        }

        if ($ShouldAlert) {
            $Payload = @{
                secret           = $SharedSecret
                actionType       = $ActionType
                computerName     = $ComputerName
                operatingSystem  = if ($ComputerObj -and $ComputerObj.OperatingSystem) { $ComputerObj.OperatingSystem } else { 'Unknown' }
                osVersion        = if ($ComputerObj -and $ComputerObj.OperatingSystemVersion) { $ComputerObj.OperatingSystemVersion } else { 'Unknown' }
                description      = if ($ComputerObj -and $ComputerObj.Description) { $ComputerObj.Description } else { '' }
                performedBy      = $PerformedBy
                performedByName  = $PerformedByDisplayName
                timestamp        = $Event.TimeCreated.ToString('yyyy-MM-ddTHH:mm:ssZ')
                dcName           = $env:COMPUTERNAME
                eventId          = [int]$Event.Id
            }

            $Body = $Payload | ConvertTo-Json -Depth 3
            Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $Body -ContentType 'application/json' -TimeoutSec 10
        }

        # Update lock file after each event
        $Event.RecordId | Out-File -FilePath $LockFile -Force
    }

} catch {
    Write-EventLog -LogName Application -Source 'ADGroupMonitor' -EventId 3001 -EntryType Error -Message "Failed to process device event: $_"
} finally {
    $Mutex.ReleaseMutex()
    $Mutex.Dispose()
}