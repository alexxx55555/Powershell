Import-Module ActiveDirectory -ErrorAction SilentlyContinue

# Configuration
$targetContainer = "OU=Users,OU=Alex,DC=alex,DC=local"
$result = @()

# 1. Find users who are CURRENTLY locked out
$lockedUsers = Search-ADAccount -LockedOut -SearchBase $targetContainer

foreach ($user in $lockedUsers) {
    # 2. Search Security logs for Event ID 4740 (Lockout) specifically for this user
    # This ensures we get the source computer and the real event time
    $latestEvent = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID      = 4740
        Data    = $user.SamAccountName
    } -MaxEvents 1 -ErrorAction SilentlyContinue
    
    $computer = "UNKNOWN"
    $eventTime = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') # Default fallback

    if ($latestEvent) {
        # Extract the real time the event was written to the log
        $eventTime = $latestEvent.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss')
        
        # Property index 1 is the Caller Computer Name in a 4740 event
        if ($latestEvent.Properties[1].Value) {
            $computer = $latestEvent.Properties[1].Value
        }
    }
    
    # 3. Get the display name from AD for a professional look in Slack
    $adUser = Get-ADUser -Identity $user.SamAccountName -Properties DisplayName -ErrorAction SilentlyContinue
    
    $fullName = "Unknown"
    if ($adUser.DisplayName) {
        $fullName = $adUser.DisplayName
    } elseif ($user.Name) {
        $fullName = $user.Name
    }
    
    # 4. Create the object for n8n consumption
    $result += [PSCustomObject]@{
        Timestamp      = $eventTime  # The ACTUAL lockout time
        Username       = $user.SamAccountName
        FullName       = $fullName
        CallerComputer = $computer
    }
}

# 5. Output as JSON for n8n to parse
if ($result.Count -eq 0) {
    Write-Output '[]'
} else {
    $result | ConvertTo-Json -Compress
}