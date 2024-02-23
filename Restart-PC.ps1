$computerName = Read-Host -Prompt "Enter Host Name"

$errormsg = $true

try{

    $computerIP = Resolve-DnsName "$computerName.alex.local" -DnsOnly -ErrorAction Stop | select -ExpandProperty IPAddress

}

catch [System.ComponentModel.Win32Exception]{

    Write-warning "Cannot Resolve hostname."

    $errormsg = $false

 

}

 

if($errormsg){

    $Error.clear()

    $adminCreds = Get-Credential $vinokura

 

    try{

        Write-Host "Trying to restart $computerName ..." -ForegroundColor Cyan

        Restart-Computer -ComputerName $computerIP -Credential $adminCreds -Force -ErrorAction Stop

    }

    catch{

        if($Error[0] -like "*Access is denied*"){

            Write-warning "Wrong Credentials."

        }

        elseif($Error[0] -like "*cannot be resolved*"){

            Write-warning "Cannot Resolve hostname."

 

        }

        elseif($Error[0] -like "*RPC server*"){

            Write-warning "Check the machine connection."

        }

        Read-Host -Prompt "Press Enter to exit" 

    }

    if(!$Error[0]){

        Write-Host "Restarting Machine" -ForegroundColor Green


        Read-Host -Prompt "Press Enter to exit"

    }

 

}


 

 