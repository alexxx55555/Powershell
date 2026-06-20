#Requires -RunAsAdministrator
# ============================================================
# Brute Force Detection Monitor (Domain-Wide)
# Runs every 5 minutes via Scheduled Task on one DC
# Queries all domain computers + DCs for failed logons
# Alerts when 5+ failed logons from same source in 10 minutes
# Resolves source IPs to AD computer names
# ============================================================

$WebhookUrl = 'https://n8n.pi.alex-it.net/webhook/brute-force-alert'
$SharedSecret = 'n8w-GmC9x$kQ2vLpR7fT4bYe!Aj6Xs8Z'
$AlertFile = 'C:\Scripts\brute_force_alerted.txt'
$LogFile = 'C:\Scripts\brute_force_monitor.log'
$Threshold = 5
$TimeWindowMinutes = 10
$AlertCooldownMinutes = 30

# Trusted IPs to exclude from alerts
$ExcludeIPs = @('192.168.1.5', '192.168.1.89')

# ============================================================
# Logging
# ============================================================
function Write-Log {
    param([string]$Message)
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts  $Message" | Out-File -FilePath $LogFile -Append -Force
}

# ============================================================
# Resolve IP to AD computer name (DNS + AD fallback + cache)
# ============================================================
$script:ResolvedIPCache = @{}

function Get-ComputerNameFromIP {
    param([string]$IP)

    if (-not $IP -or $IP -eq '-' -or $IP -eq '::1' -or $IP -eq 'LOCAL' -or $IP -eq '127.0.0.1') {
        return 'LOCAL'
    }

    if ($script:ResolvedIPCache.ContainsKey($IP)) {
        return $script:ResolvedIPCache[$IP]
    }

    $resolved = $null

    # Try DNS reverse lookup
    try {
        $dns = [System.Net.Dns]::GetHostEntry($IP)
        $hostname = ($dns.HostName -split '\.')[0]
        if ($hostname) {
            try {
                $comp = Get-ADComputer -Identity $hostname -ErrorAction Stop
                $resolved = $comp.Name
            } catch {
                $resolved = $hostname
            }
        }
    } catch {}

    # Fallback: search AD for matching IPv4
    if (-not $resolved) {
        try {
            $match = Get-ADComputer -Filter "IPv4Address -eq '$IP'" -Properties IPv4Address -ErrorAction Stop | Select-Object -First 1
            if ($match) { $resolved = $match.Name }
        } catch {}
    }

    if (-not $resolved) { $resolved = $IP }
    $script:ResolvedIPCache[$IP] = $resolved
    return $resolved
}

# ============================================================
# Load previously alerted sources
# ============================================================
$AlertedSources = @{}
if (Test-Path $AlertFile) {
    try {
        $AlertedSources = Get-Content $AlertFile -Raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    } catch {
        $AlertedSources = @{}
    }
}

# Clean expired cooldowns
$Now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$ExpiredKeys = @($AlertedSources.Keys | Where-Object { ($Now - $AlertedSources[$_]) -gt ($AlertCooldownMinutes * 60) })
foreach ($key in $ExpiredKeys) {
    $AlertedSources.Remove($key)
}

# ============================================================
# Discover all domain computers
# ============================================================
try {
    $DomainComputers = Get-ADComputer -Filter 'Enabled -eq $true' -Properties DNSHostName, OperatingSystem |
        Where-Object { $_.DNSHostName } |
        Select-Object -ExpandProperty DNSHostName

    Write-Log "Found $($DomainComputers.Count) enabled computers in AD"
} catch {
    Write-Log "ERROR: Failed to query AD for computers: $_"
    Write-EventLog -LogName Application -Source 'ADGroupMonitor' -EventId 4001 -EntryType Error -Message "Brute force monitor: Failed to query AD computers: $_"
    exit 1
}

# ============================================================
# Query each computer for failed logons
# ============================================================
$StartTime = (Get-Date).AddMinutes(-$TimeWindowMinutes)
$AllParsedEvents = @()

foreach ($Computer in $DomainComputers) {
    $shortName = ($Computer -split '\.')[0]

    # Test if machine is reachable (fast check)
    # Fast reachability check (1 second timeout)
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $result = $tcp.BeginConnect($Computer, 5985, $null, $null)
        $success = $result.AsyncWaitHandle.WaitOne(1000)
        if (-not $success) {
            Write-Log "SKIP: $shortName is offline"
            continue
        }
        $tcp.EndConnect($result)
    } catch {
        Write-Log "SKIP: $shortName is offline"
        continue
    } finally {
        $tcp.Close()
    }

    try {
        $FailedLogons = Get-WinEvent -ComputerName $Computer -FilterHashtable @{
            LogName   = 'Security'
            Id        = 4625
            StartTime = $StartTime
        } -ErrorAction SilentlyContinue

        if (-not $FailedLogons -or $FailedLogons.Count -eq 0) {
            continue
        }

        Write-Log "Found $($FailedLogons.Count) failed logon(s) on $shortName"

        foreach ($Event in $FailedLogons) {
            [xml]$EventXml = $Event.ToXml()
            $Data = @{}
            foreach ($d in $EventXml.Event.EventData.Data) {
                $Data[$d.Name] = $d.'#text'
            }

            $SourceIP = $Data['IpAddress']
            if (-not $SourceIP -or $SourceIP -eq '-' -or $SourceIP -eq '::1') {
                $SourceIP = 'LOCAL'
            }

            $AllParsedEvents += @{
                TargetUser    = $Data['TargetUserName']
                TargetDomain  = $Data['TargetDomainName']
                SourceIP      = $SourceIP
                SourceHost    = if ($Data['WorkstationName']) { $Data['WorkstationName'] } else { 'Unknown' }
                LogonType     = $Data['LogonType']
                FailureReason = $Data['Status']
                SubStatus     = $Data['SubStatus']
                ProcessName   = if ($Data['ProcessName']) { $Data['ProcessName'] } else { '' }
                TimeCreated   = $Event.TimeCreated
                MonitoredOn   = $shortName   # which machine this event came from
            }
        }
    } catch {
        Write-Log "ERROR: Failed to query $shortName — $_"
    }
}

Write-Log "Total failed logon events collected: $($AllParsedEvents.Count)"

if ($AllParsedEvents.Count -eq 0) {
    $AlertedSources | ConvertTo-Json | Out-File -FilePath $AlertFile -Force
    exit 0
}

# ============================================================
# Group by source IP + target user, exclude trusted IPs
# ============================================================
$Grouped = $AllParsedEvents |
    Where-Object { $ExcludeIPs -notcontains $_.SourceIP } |
    Group-Object { '{0}|{1}' -f $_.SourceIP, $_.TargetUser }

foreach ($Group in $Grouped) {
    if ($Group.Count -ge $Threshold) {
        $Source = $Group.Group[0]
        $AlertKey = '{0}|{1}' -f $Source.SourceIP, $Source.TargetUser

        # Skip if already alerted within cooldown
        if ($AlertedSources.ContainsKey($AlertKey)) {
            continue
        }

        # Resolve source IP to AD computer name
        $ResolvedName = Get-ComputerNameFromIP -IP $Source.SourceIP
        # If source is LOCAL/127.0.0.1, use the machine name and look up its real IP
        if ($ResolvedName -eq 'LOCAL' -or $ResolvedName -eq '127.0.0.1') {
            $ResolvedName = $Source.MonitoredOn
            try {
                $machineIP = (Resolve-DnsName -Name $Source.MonitoredOn -Type A -ErrorAction Stop | Select-Object -First 1).IPAddress
                if ($machineIP) { $Source.SourceIP = $machineIP }
            } catch {
                try {
                    $machineIP = ([System.Net.Dns]::GetHostAddresses($Source.MonitoredOn) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1).IPAddressToString
                    if ($machineIP) { $Source.SourceIP = $machineIP }
                } catch {}
            }
        }

        # Map failure codes
        $FailureMessage = switch ($Source.SubStatus) {
            '0xC0000064' { 'User does not exist' }
            '0xC000006A' { 'Wrong password' }
            '0xC0000072' { 'Account disabled' }
            '0xC000006F' { 'Outside logon hours' }
            '0xC0000070' { 'Workstation restriction' }
            '0xC0000071' { 'Password expired' }
            '0xC0000234' { 'Account locked out' }
            '0xC0000193' { 'Account expired' }
            default       { 'Unknown ({0})' -f $Source.SubStatus }
        }

        # Map logon type
        $LogonTypeName = switch ($Source.LogonType) {
            '2'  { 'Interactive (local)' }
            '3'  { 'Network (SMB/share)' }
            '7'  { 'Unlock' }
            '8'  { 'Network Cleartext' }
            '10' { 'Remote Desktop (RDP)' }
            '11' { 'Cached Interactive' }
            default { 'Type {0}' -f $Source.LogonType }
        }

        # Get display name if user exists in AD
        $DisplayName = ''
        try {
            $ADUser = Get-ADUser -Identity $Source.TargetUser -Properties DisplayName -ErrorAction Stop
            if ($ADUser.DisplayName) { $DisplayName = $ADUser.DisplayName }
        } catch {}

        # List all machines where attempts were seen
        $AffectedMachines = ($Group.Group | ForEach-Object { $_.MonitoredOn } | Select-Object -Unique) -join ', '

        $Payload = @{
            secret          = $SharedSecret
            targetUser      = if ($Source.TargetDomain) { '{0}\{1}' -f $Source.TargetDomain, $Source.TargetUser } else { $Source.TargetUser }
            displayName     = $DisplayName
            sourceIP        = $Source.SourceIP
            sourceComputer  = $ResolvedName
            sourceHost      = if ($Source.SourceHost -and $Source.SourceHost -ne 'Unknown') { $Source.SourceHost } else { $ResolvedName }
            failureCount    = $Group.Count
            failureReason   = $FailureMessage
            logonType       = $LogonTypeName
            timeWindow      = $TimeWindowMinutes
            firstAttempt    = ($Group.Group | Sort-Object TimeCreated | Select-Object -First 1).TimeCreated.ToString('yyyy-MM-ddTHH:mm:ssZ')
            lastAttempt     = ($Group.Group | Sort-Object TimeCreated -Descending | Select-Object -First 1).TimeCreated.ToString('yyyy-MM-ddTHH:mm:ssZ')
            affectedMachines = $AffectedMachines
            dcName          = $env:COMPUTERNAME
        }

        $Body = $Payload | ConvertTo-Json -Depth 3

        try {
            Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $Body -ContentType 'application/json' -TimeoutSec 10
            Write-Log "ALERT SENT: $($Source.SourceIP) ($ResolvedName) -> $($Source.TargetUser) [$($Group.Count) failures] on $AffectedMachines"
        } catch {
            Write-Log "ERROR: Failed to send webhook for $AlertKey — $_"
        }

        $AlertedSources[$AlertKey] = $Now
    }
}

# Save alerted sources
$AlertedSources | ConvertTo-Json | Out-File -FilePath $AlertFile -Force
Write-Log "Run complete"