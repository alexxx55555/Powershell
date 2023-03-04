do {
    $username = Read-Host -Prompt 'Enter Logon Name'

    If ([string]::IsNullOrEmpty($username)) { 
Break
    }
    ElseIf ($username -ne $null) {
        if (Get-ADUser -LDAPFilter "(sAMAccountName=$username)") {
            'User found in AD'
        }
        else {
            'User does not exist in AD'
        }
    }
}
while ($username -ne $null)
Write-Host -ForegroundColor Red 'Done, Thank You'