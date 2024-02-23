# Prompt the user to enter the computer name or IP address
$computer = Read-Host -Prompt "Enter Computer Name or IP Address"

# Try to resolve the DNS name or IP address of the computer
if ($computer -as [ipaddress]) {
    # If the user entered an IP address, use it directly
    $computerIP = $computer
}
else {
    # Otherwise, try to resolve the DNS name of the computer
    try {
        $computerIP = Resolve-DnsName -Name "$computer.alex.local" -DnsOnly -ErrorAction Stop |
                      Select-Object -ExpandProperty IPAddress
    }
    catch {
        Write-Warning "Cannot resolve hostname."
        Read-Host -Prompt "Press Enter to exit"
        exit
    }
}

# Get the credentials of the administrator
$adminCreds = Get-Credential -Credential "alex\$env:USERNAME"

# Restart the computer
try {
    Write-Output "Trying to restart $computer ..."
    $params = @{
        ComputerName = $computerIP
        Credential   = $adminCreds
        Force        = $true
        ErrorAction  = 'Stop'
    }
    Restart-Computer @params
    Write-Output "Restarting machine"
    
}
catch {
    switch -regex ($Error[0].Exception.Message) {
        "Access is denied" { Write-Warning "Wrong credentials." }
        "cannot be resolved" { Write-Warning "Cannot resolve hostname." }
        "RPC server" { Write-Warning "Check the machine connection." }
        default { Write-Warning "An error occurred: $($_.Exception.Message)" }
    }

    }