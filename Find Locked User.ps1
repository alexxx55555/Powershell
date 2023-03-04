  start-transcript

  Write-Warning 'Please Run This Script Using Administrator User!'
  
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) `
{ Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }


   $SamAccountName = Read-Host -Prompt 'Please Enter Username' 

    while ($SamAccountName -ne 'Stop')
    {

    if ($SamAccountName -eq "" -or $SamAccountName -eq "\" -or $SamAccountName -eq "/" )
    {
      Write-Host -ForegroundColor Magenta - "Username can't be blank or used by special characters and spaces!"  
    }
    else
    {
        
   
    $accountExist = [bool] (Get-ADUser -Filter { SamAccountName -eq $SamAccountName })

    if ($accountExist -eq "true" ){

    # The account exist and now we need to see if its locked out.


        if ( (Get-ADUser $SamAccountName  -Properties * | Select-Object LockedOut) -match "True")

        
        {

        Write-Host  -ForegroundColor Yellow "The user '$SamAccountName' is locked."

        $PDC = (Get-ADDomainController -Filter * | Where-Object {$_.OperationMasterRoles -contains "PDCEmulator"})
        #Get user info
        $UserInfo = Get-ADUser -Identity $SamAccountName

        #Search PDC for lockout events with ID 4740
        $LockedOutEvents = Get-WinEvent -ComputerName  $PDC -FilterHashtable @{LogName='Security';Id=4740} -ErrorAction Stop | Sort-Object -Property TimeCreated -Unique | Select-Object -Last 3
      
        #Parse and filter out lockout events
        Foreach($Event in $LockedOutEvents)
            {
            If($Event | Where {$_.Properties[2].value -match $UserInfo.SID.Value})
                {

                    $Event | Select-Object -Property @(
                    @{Label = 'User Name'; Expression = {$_.Properties[0].Value}}
                    @{Label = 'Domain Controller'; Expression = {$_.MachineName}}
                    @{Label = 'Lockout Time Stamp'; Expression = {$_.TimeCreated}}
                    @{Label = 'Message'; Expression = {$_.Message -split "`r" | Select -First 1}}
                    @{Label = 'Lockout Source'; Expression = {$_.Properties[1].Value}}
                     )

               }
            }

           
          if ( (Get-ADUser $SamAccountName  -Properties * | Select-Object LockedOut) -match "True") 
          {
              Unlock-ADAccount -Identity $SamAccountName -Confirm
          }
                          
              

        }

        if ( (Get-ADUser $SamAccountName  -Properties * | Select-Object LockedOut) -match "False" )

        {
            Write-Host  -ForegroundColor Green "The user '$SamAccountName' is not locked."
        }

   

    }


    else {

       
        
        Write-Host  -ForegroundColor Red "The user "$SamAccountName" does not exist. Please check that you have typed correct username.  "
        }
    }
    
    $SamAccountName = Read-Host -Prompt 'Please Enter Username'

}

 Read-Host -Prompt 'Press Enter to Exit' 


 