param(
    [string]$FirstName,
    [string]$LastName,
    [int]$EmployeeNumber,
    [string]$JobTitle,
    [string]$Department,
    [string]$ManagerSam,
    [string]$OfficePhone,
    [string]$OfficeLocation,
    [string]$SourceUsername
)

function Output-ErrorJson {
    param([string]$message)
    [PSCustomObject]@{ error = $message } | ConvertTo-Json
    exit 1
}

try {
    Import-Module ActiveDirectory -ErrorAction Stop
} catch {
    Output-ErrorJson "Could not import ActiveDirectory module. $_"
}

$ProgressPreference = 'SilentlyContinue'

# --- Connect to Exchange ---
try {
    $s = New-PSSession -ConfigurationName Microsoft.Exchange `
        -ConnectionUri "http://EX2019/powershell/" `
        -Authentication Kerberos
    Import-PSSession -Session $s -AllowClobber -DisableNameChecking | Out-Null
} catch {
    Output-ErrorJson "Could not connect/import Exchange session. $_"
}

# --- Input Validation ---
if (-not $FirstName -or -not $LastName) {
    Output-ErrorJson "FirstName and LastName are required."
}

# --- Employee Number Uniqueness Logic ---
function Get-AvailableEmployeeNumber {
    param([int]$EmployeeNumber)
    $allUsers = Get-ADUser -Filter * -Properties EmployeeNumber
    $usedNumbers = $allUsers | Where-Object { $_.EmployeeNumber -match '^\d+$' } | ForEach-Object { [int]$_.EmployeeNumber }
    $origNumber = $EmployeeNumber
    $conflictingUser = $allUsers | Where-Object { $_.EmployeeNumber -eq $EmployeeNumber }
    if ($conflictingUser) {
        while ($usedNumbers -contains $EmployeeNumber) {
            $EmployeeNumber++
        }
    }
    return @{
        EmployeeNumber = $EmployeeNumber
        ConflictUser  = $conflictingUser
        OriginalNumber = $origNumber
    }
}

# --- Password Generation ---
function Generate-Password {
    $lower = ((97..122) | Get-Random -Count 4 | ForEach-Object {[char]$_}) -join ''
    $upper = ((65..90) | Get-Random -Count 2 | ForEach-Object {[char]$_}) -join ''
    $digits = ((48..57) | Get-Random -Count 1 | ForEach-Object {[char]$_}) -join ''
    $symbols = ((33..47) + (58..64) + (91..96) + (123..126) | Get-Random -Count 1 | ForEach-Object {[char]$_}) -join ''
    $combined = $lower + $upper + $digits + $symbols
    return ($combined.ToCharArray() | Get-Random -Count $combined.Length) -join ''
}

# --- Build API-Friendly Report ---
function Get-UserCreationReport {
    param(
        [string]$FirstName,
        [string]$LastName,
        [string]$EmployeeNumber,
        [string]$Department,
        [string]$JobTitle,
        [string]$Username,
        [string]$ManagerFullName,
        [string]$OfficeLocation,
        [string]$OfficePhone,
        [string]$Email,
        [string[]]$DLGroupsCopied,
        [string[]]$SecurityGroupsCopied,
        [string]$Password
    )
    $report = @"
New User Created:

First Name: $FirstName
Last Name: $LastName
Employee Number: $EmployeeNumber
Department: $Department
Job Title: $JobTitle
Username: $Username
Manager: $ManagerFullName
Office Location: $OfficeLocation
Office Phone: $OfficePhone
E-mail: $Email
DL Groups Copied: $($DLGroupsCopied -join ', ')
Security Groups Copied: $($SecurityGroupsCopied -join ', ')
Initial Password: $Password

Make sure to save the initial password in a safe location!

Alex IT
"@
    return $report
}

# --- Use EmployeeNumber After Conflict Checking ---
$empNumResult = Get-AvailableEmployeeNumber -EmployeeNumber $EmployeeNumber
$finalEmployeeNumber = $empNumResult.EmployeeNumber
$conflictMsg = ""
if ($empNumResult.ConflictUser) {
    $conflictMsg = "Requested EmployeeNumber '$($empNumResult.OriginalNumber)' is already used by $($empNumResult.ConflictUser.Name) [$($empNumResult.ConflictUser.SamAccountName)]. Assigned next available: '$finalEmployeeNumber'."
}

# --- Display Name Logic ---
$adDisplayName = "$FirstName $LastName"
$existingUsersWithSameName = Get-ADUser -Filter { Name -eq $adDisplayName }
if ($existingUsersWithSameName) {
    $adDisplayName = "$FirstName $LastName ($finalEmployeeNumber)"
}

# --- Unique Username: first name + N letters of last name ---
$username = $null
$usernameBase = $FirstName.ToLower()
$maxLen = $LastName.Length

for ($len = 1; $len -le $maxLen; $len++) {
    $testUsername = ($usernameBase + $LastName.Substring(0, $len).ToLower())
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$testUsername'")) {
        $username = $testUsername
        break
    }
}
if (-not $username) {
    $username = ($usernameBase + $LastName.ToLower())
}

$email = "$username@alex.com"

# --- Generate Password ---
$password = Generate-Password
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force

# --- Lookup Manager (try SAM first, then full name) ---
$manager = $null
$managerFullName = ""
$managerConflict = ""
if ($ManagerSam -and $ManagerSam.Trim() -ne "") {
    try {
        # Try as SAM first
        $manager = Get-ADUser -Filter "SamAccountName -eq '$ManagerSam'" -Properties GivenName, Surname -ErrorAction SilentlyContinue
        if (-not $manager) {
            # Then try as full name
            $manager = Get-ADUser -Filter "Name -eq '$ManagerSam'" -Properties GivenName, Surname -ErrorAction SilentlyContinue
        }
        if ($manager) {
            if ($manager -is [array] -and $manager.Count -gt 1) {
                $managerConflict = "Multiple managers found for '$ManagerSam'. Manager not set."
                $manager = $null
            } else {
                $managerFullName = if ($manager.GivenName -and $manager.Surname) { 
                    "$($manager.GivenName) $($manager.Surname)" 
                } else { 
                    $manager.Name 
                }
            }
        } else {
            $managerConflict = "Manager '$ManagerSam' not found."
        }
    } catch {
        $managerConflict = "Error looking up manager '$ManagerSam': $_"
    }
} else {
    $managerConflict = "No manager specified."
}
if ($managerConflict) {
    if ($conflictMsg) { $conflictMsg += " $managerConflict" } else { $conflictMsg = $managerConflict }
    $managerFullName = $managerConflict  # Use message in output for visibility
}

# --- Create AD User ---
$adUserParams = @{
    Name              = $adDisplayName
    GivenName         = $FirstName
    Surname           = $LastName
    SamAccountName    = $username
    UserPrincipalName = $email
    AccountPassword   = $securePassword
    Path              = "OU=Users,OU=Alex,DC=alex,DC=local"
    Enabled           = $true
    EmployeeNumber    = $finalEmployeeNumber
    OfficePhone       = $OfficePhone
    Office            = $OfficeLocation
    Department        = $Department
    Title             = $JobTitle
}
if ($manager) { 
    $adUserParams["Manager"] = $manager.DistinguishedName 
}

try {
    New-ADUser @adUserParams
} catch {
    Output-ErrorJson "Failed to create AD user: $_"
}

# --- Copy Group Memberships (try SAM first, then full name) ---
$DLGroupsCopied = @()
$SecurityGroupsCopied = @()
$groupCopyMessage = ""
if ($SourceUsername -and $SourceUsername.Trim() -ne "") {
    try {
        $sourceUser = $null
        # Try as SAM first
        $sourceUser = Get-ADUser -Filter "SamAccountName -eq '$SourceUsername'" -Properties MemberOf -ErrorAction SilentlyContinue
        if (-not $sourceUser) {
            # Then try as full name
            $sourceUser = Get-ADUser -Filter "Name -eq '$SourceUsername'" -Properties MemberOf -ErrorAction SilentlyContinue
        }
        if ($sourceUser) {
            if ($sourceUser -is [array] -and $sourceUser.Count -gt 1) {
                $groupCopyMessage = "Multiple source users found for '$SourceUsername'. Groups not copied."
                $sourceUser = $null
            } elseif ($sourceUser.MemberOf) {
                $groupsCopiedCount = 0
                foreach ($group in $sourceUser.MemberOf) {
                    $adGroup = Get-ADGroup -Identity $group -Properties GroupCategory -ErrorAction SilentlyContinue
                    if ($adGroup) {
                        try {
                            Add-ADGroupMember -Identity $adGroup -Members $username -ErrorAction Stop
                            if ($adGroup.GroupCategory -eq 'Security') {
                                $SecurityGroupsCopied += $adGroup.Name
                            } else {
                                $DLGroupsCopied += $adGroup.Name
                            }
                            $groupsCopiedCount++
                        } catch {
                            # Ignore minor errors (e.g., already a member)
                        }
                    }
                }
                if ($groupsCopiedCount -eq 0) {
                    $groupCopyMessage = "Source user '$SourceUsername' found but has no group memberships to copy."
                }
            } else {
                $groupCopyMessage = "Source user '$SourceUsername' found but has no group memberships."
            }
        } else {
            $groupCopyMessage = "Source user '$SourceUsername' not found."
        }
    } catch {
        $groupCopyMessage = "Error copying groups from '$SourceUsername': $_"
    }
} else {
    $groupCopyMessage = "No source username provided for group copying."
}
if ($groupCopyMessage) {
    if ($conflictMsg) { $conflictMsg += " $groupCopyMessage" } else { $conflictMsg = $groupCopyMessage }
}

# --- Enable Exchange Mailbox ---
try {
    Get-User -Identity $username | Enable-Mailbox | Out-Null
} catch {
    # Ignore for now; add to conflict if needed
}

# --- Build Report String ---
$creationReport = Get-UserCreationReport `
    -FirstName $FirstName `
    -LastName $LastName `
    -EmployeeNumber $finalEmployeeNumber `
    -Department $Department `
    -JobTitle $JobTitle `
    -Username $username `
    -ManagerFullName $managerFullName `
    -OfficeLocation $OfficeLocation `
    -OfficePhone $OfficePhone `
    -Email $email `
    -DLGroupsCopied $DLGroupsCopied `
    -SecurityGroupsCopied $SecurityGroupsCopied `
    -Password $password

# --- Output API-Ready JSON ---
$userDetails = [PSCustomObject]@{
    FirstName           = $FirstName
    LastName            = $LastName
    EmployeeNumber      = $finalEmployeeNumber
    Department          = $Department
    JobTitle            = $JobTitle
    Username            = $username
    Manager             = $managerFullName
    OfficeLocation      = $OfficeLocation
    OfficePhone         = $OfficePhone
    Email               = $email
    DLGroupsCopied      = $DLGroupsCopied
    SecurityGroupsCopied= $SecurityGroupsCopied
    Password            = $password
    ConflictMessage     = $conflictMsg
    Report              = $creationReport
}

$userDetails | ConvertTo-Json -Depth 4