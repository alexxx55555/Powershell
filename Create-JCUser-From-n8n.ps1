param(
    [string]$FirstName,
    [string]$LastName,
    [int]$EmployeeNumber,
    [string]$JobTitle,
    [string]$Department,
    [string]$ManagerSam,
    [string]$OfficePhone,
    [string]$OfficeLocation
)

# -- SET THIS! --
$JumpCloudApiKey = "jca_6Laq2ybRvaGKSdrU4YVogE58kwHhGR69Sjcw"
$JumpCloudHeaders = @{
    "x-api-key" = $JumpCloudApiKey
    "Content-Type" = "application/json"
    "Accept" = "application/json"
}

function Output-ErrorJson {
    param([string]$message)
    [PSCustomObject]@{ error = $message } | ConvertTo-Json
    exit 1
}

if (-not $FirstName -or -not $LastName) {
    Output-ErrorJson "FirstName and LastName are required."
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
$password = Generate-Password

# --- Step 1: Get all users and check for duplicate display name ---
$searchName = "$FirstName $LastName"
try {
    $allUsersResp = Invoke-RestMethod -Uri "https://console.jumpcloud.com/api/systemusers?limit=100" -Headers $JumpCloudHeaders -Method Get
    $allUsersResp = Invoke-RestMethod -Uri "https://console.jumpcloud.com/api/systemusers?limit=100" -Headers $JumpCloudHeaders -Method Get

# Employee Number uniqueness logic
$usedEmployeeNumbers = $allUsersResp.results | Where-Object { $_.employeeIdentifier -match '^\d+$' } | ForEach-Object { [int]$_.employeeIdentifier }
$origNumber = $EmployeeNumber
while ($usedEmployeeNumbers -contains $EmployeeNumber) {
    $EmployeeNumber++
}
} catch {
    Output-ErrorJson "Failed to query JumpCloud users: $_"
}
$existingUsersWithSameName = $allUsersResp.results | Where-Object { $_.displayname -eq $searchName }

$adDisplayName = $searchName
if ($existingUsersWithSameName.Count -ge 1) {
    $adDisplayName = "$FirstName $LastName ($EmployeeNumber)"
}

# --- Step 2: Unique Username Logic ---
$existingUsernames = $allUsersResp.results | Select-Object -ExpandProperty username
$usernameBase = $FirstName.ToLower()
$maxLen = $LastName.Length
$username = $null
for ($len = 1; $len -le $maxLen; $len++) {
    $testUsername = ($usernameBase + $LastName.Substring(0, $len).ToLower())
    if ($existingUsernames -notcontains $testUsername) {
        $username = $testUsername
        break
    }
}
if (-not $username) {
    $username = ($usernameBase + $LastName.ToLower())
}
$email = "$username@alex-it.net"

# --- Step 3: Build JSON Payload ---
$userPayload = @{
    username     = $username
    email        = $email
    firstname    = $FirstName
    lastname     = $LastName
    displayname  = $adDisplayName
    employeeIdentifier = "$EmployeeNumber"
    department   = $Department
    jobTitle     = $JobTitle
    attributes   = @(
        @{ name = "OfficeLocation"; value = $OfficeLocation }
        @{ name = "OfficePhone"; value = $OfficePhone }
        @{ name = "Manager"; value = $ManagerSam }
    )
    activated    = $true
    password     = $password
} | ConvertTo-Json -Compress

# --- Step 4: Create the JumpCloud User ---
try {
    $newUserResp = Invoke-RestMethod -Uri "https://console.jumpcloud.com/api/systemusers" -Headers $JumpCloudHeaders -Method Post -Body $userPayload
} catch {
    Output-ErrorJson "Failed to create JumpCloud user: $_"
}

# --- Step 5: Output Result JSON ---
$userDetails = [PSCustomObject]@{
    FirstName       = $FirstName
    LastName        = $LastName
    EmployeeNumber  = $EmployeeNumber
    DisplayName     = $adDisplayName
    Username        = $username
    Email           = $email
    JobTitle        = $JobTitle
    Department      = $Department
    Manager         = $ManagerSam
    OfficeLocation  = $OfficeLocation
    OfficePhone     = $OfficePhone
    Password        = $password
}
$userDetails | ConvertTo-Json -Depth 4
