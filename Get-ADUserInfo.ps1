param(
    [Parameter(Mandatory=$true)]
    [string]$Username
)
function Get-ADUserInfo {
    param([string]$UserName)
    $PreferredDC = "DC3.alex.local"
    try {
        if (-not (Get-Module -ListAvailable ActiveDirectory)) {
            throw "ActiveDirectory module is not installed on this system."
        }
        Import-Module ActiveDirectory -ErrorAction Stop
        $user = Get-ADUser -Filter "sAMAccountName -eq '$UserName'" -Server $PreferredDC -Properties *, EmployeeNumber, LockedOut, Description
        if (-not $user) {
            return @{
                status  = "error"
                message = "User '$UserName' not found in Active Directory"
            } | ConvertTo-Json -Compress
        }
        $managerName = "None"
        if ($user.Manager) {
            try {
                $managerName = (Get-ADUser $user.Manager -Server $PreferredDC -Properties DisplayName).DisplayName
            } catch {
                $managerName = "Unable to retrieve"
            }
        }
        $dlGroups = @()
        $securityGroups = @()
        try {
            $userDN = $user.DistinguishedName
            $allGroups = Get-ADGroup -Filter "member -eq '$userDN'" -Server $PreferredDC
            $dlGroups = @($allGroups | Where-Object { $_.GroupCategory -eq 'Distribution' } | Select-Object -ExpandProperty Name)
            $securityGroups = @($allGroups | Where-Object { $_.GroupCategory -eq 'Security' } | Select-Object -ExpandProperty Name)
        } catch {
            $securityGroups = @("Error retrieving groups: $($_.Exception.Message)")
        }
        $dateFormat = "HH:mm:ss dd-MM-yyyy"
        $result = @{
            status = "success"
            data = @{
                username           = $user.SamAccountName
                employeeNumber     = $user.EmployeeNumber
                fullName           = $user.DisplayName
                email              = $user.Mail
                description        = $user.Description
                title              = $user.Title
                telephoneNumber    = $user.TelephoneNumber
                manager            = $managerName
                enabled            = $user.Enabled
                locked             = $user.LockedOut
                lastLogon          = if ($user.LastLogonDate) { $user.LastLogonDate.ToString($dateFormat) } else { "Never" }
                passwordLastSet    = if ($user.PasswordLastSet) { $user.PasswordLastSet.ToString($dateFormat) } else { "Never" }
                accountCreatedDate = if ($user.Created) { $user.Created.ToString($dateFormat) } else { "N/A" }
                groups = @{
                    distribution = $dlGroups
                    security     = $securityGroups
                }
            }
        }
        return $result | ConvertTo-Json -Depth 10 -Compress
    }
    catch {
        return @{
            status  = "error"
            message = "AD query failed: $($_.Exception.Message)"
        } | ConvertTo-Json -Compress
    }
}
Get-ADUserInfo -UserName $Username