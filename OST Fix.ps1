<#

use this powershell script as administrator

   script actions are:

   1. kill Outlook & Skype processes

   2. rename OST files to OST.old

   3. start Outlook & Skype

#>

#### Created by Shay Mor EUC 5.11.20 ####

 

$Processes = @('outlook', 'lync', 'ucmapi')

try {

    foreach ($p in $Processes) {

        if (Get-Process -name $p -ErrorAction SilentlyContinue) {

            Stop-Process -name $p -Force -ErrorAction SilentlyContinue

        }

    }

   

    $path = "$env:LOCALAPPDATA\Microsoft\Outlook"

    #delete all '*.old' items

    $olditems = get-item -Path $path\*.old

    foreach ($old in $olditems) {

        Remove-Item $old

    }

 

    #Rename '.OST' file to '.ost.old'

    $ostfiles = Get-Item -Path $path\*.ost

    foreach ($ost in $ostfiles) {

        while (!(test-path $ost'.old')) {

            Start-Sleep 2

            Rename-Item -Path $ost -NewName $ost'.old' -Force       

        }

    }

    Start-Process outlook

    Start-Process lync

}

catch {

    $ErrorMessage = $_.Exception.Message

    $FailedItem = $_.Exception.ItemName

    Write-Output "Failed: $FailedItem The error message was $ErrorMessage"

}