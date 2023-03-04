Import-Module ActiveDirectory

#Check Password Policy
Function Test-PasswordForDomain {
    Param (
        [Parameter(Mandatory=$true)][string]$Password,
        [Parameter(Mandatory=$false)][string]$AccountSamAccountName = "",
        [Parameter(Mandatory=$false)][string]$AccountDisplayName,
        [Microsoft.ActiveDirectory.Management.ADEntity]$PasswordPolicy = (Get-ADDefaultDomainPasswordPolicy -ErrorAction SilentlyContinue)
    )

    If ($Password.Length -lt $PasswordPolicy.MinPasswordLength) {
        return $false
    }


   if (($AccountSamAccountName) -and ($Password -match "$AccountSamAccountName")) {
        return $false
    }
   if ($AccountDisplayName) {
    $tokens = $AccountDisplayName.Split(",.-,_ #`t")
    foreach ($token in $tokens) {
        if (($token) -and ($Password -match "$token")) {
            return $false
        }
    }
}
   
   
    return $true   
   
}

#Check if employee number is free

function Get-AvailableEmployeeNumber {
param(
    [int]$EmployeeNumber,
    [string[]]$AllNum
)

if($AllNum -contains $EmployeeNumber){
    Get-AvailableEmployeeNumber -EmployeeNumber ($EmployeeNumber + 1) -AllNum $AllNum

}
else{
    $EmployeeNumber
}

}

# Import Exchange Module
$s=New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ex2019.alex.local/powershell 
Import-PSSession -session $s -AllowClobber

# Import SFB Module
$SkypeSession = New-PSSession -Credential $Credentials -ConnectionURI https://Skype-Server.alex.local/OcsPowershell 
Import-PSSession $SkypeSession -AllowClobber


#User creation path
$ADPath = "OU=Users,OU=Alex,DC=alex,DC=local"

    

# Grab Variables from User
$firstname = Read-Host -Prompt "Enter First Name"

# Stop by empty first name
while (!($firstname -eq "")){

# Grab Variables from User
$lastname = Read-Host  -Prompt  "Enter Last Name"
 
do {                                                            
    try { 

    $EmpNumOK = $false
    While (-not $EmpNumOK) {
    $EmployeeNumber = Read-Host "Enter Employee Number"     
    If ( ($EmployeeNumber.length) -le 5) {
    $EmpNumOK = $true
    $EmployeeNumber = [int] $EmployeeNumber }
    Else {
    Write-Host -ForegroundColor Yellow "Length of $($EmployeeNumber.length) digits is invalid for employee number, please use up to 5 digits."
 
 }

}
        
    }
    catch [System.Management.Automation.PSInvalidCastException] {
       write-host -ForegroundColor Cyan "You can only use numbers!"
        
    }
}
until (($EmployeeNumber -or $EmployeeNumber -eq 0) -and $EmployeeNumber -match "^[0-9]*$")


    $allNum = 
    [Int32[]]($((Get-ADUser -Filter * -Properties EmployeeNumber).EmployeeNumber)) |
    Sort-Object -Descending 

    $newNum = Get-AvailableEmployeeNumber -EmployeeNumber $EmployeeNumber -AllNum $allNum
    if($newNum -ne $EmployeeNumber){
        write-host -ForegroundColor Green "EmployeeNumber '$EmployeeNumber' is already in use by $((Get-ADUser -Filter {EmployeeNumber -eq $EmployeeNumber}).SamAccountName)"
    }
    Write-Output "Employee number'$newNum' is Available "



$password = Read-Host -Prompt "Enter password"

while(!(Test-PasswordForDomain -Password $password)){
    write-host -ForegroundColor Yellow "Password complexity error!!!"
    $password = Read-Host -Prompt "Enter password"

}

# Set username
$i = 1
$basename = $firstname
$username = $basename + $lastName.Substring(0,$i)
$username = $username.ToLower()
   
while ((Get-ADUser -filter {SamAccountName -eq $username}).SamAccountName -eq $username)
{

  if($i -gt $lastName.Length){
        # update the basename and reset $i
        $basename = $username
        $i=1
    }

   
        $username = $baseName + $lastName.Substring(0,$i++)
        $username = $username.ToLower()
       
}

$email = $username + "@alex.local" 
if (Get-ADUser -Filter "surname -eq '$lastname' -and givenname -eq '$firstname'")

{
  
# Create the AD User
New-ADUser `
-Name "$firstname $lastname ($newNum)" `
-GivenName $firstname `
-Surname $lastname `
-EmployeeNumber $newNum `
-Displayname "$FirstName $lastname" `
-UserPrincipalName $email `
-SamAccountName $username  `
-AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
-Path $ADPath `
-Enabled 1   
}
else
{
   # Create the AD User
New-ADUser `
-Name "$firstname $lastname" `
-GivenName $firstname `
-Surname $lastname `
-EmployeeNumber $newNum `
-Displayname "$FirstName $lastname" `
-UserPrincipalName $email `
-SamAccountName $username  `
-AccountPassword (ConvertTo-SecureString $password -AsPlainText -Force) `
-Path $ADPath `
-Enabled 1   
}

# Create Mailbox
Get-User -OrganizationalUnit alex.local/alex/users -RecipientTypeDetails user | Enable-Mailbox

# Create SFB Account
Get-CsAdUser -Ou "alex.local/alex/users" -Filter `
{Enabled -ne $false} | Enable-CsUser -RegistrarPool "Skype-Server.alex.local" -SipAddressType SamAccountName -SipDomain "alex.local" 
Get-CsAdUser -OU "alex.local/alex/users" -Filter {Enabled -ne $false} | Measure-Object | FL Count 


#Check if user is creted successfully or not

$username = $username
$User = Get-ADUser -LDAPFilter "(sAMAccountName=$username)"
If ($User -eq $Null) {Write-Host  -ForegroundColor DarkRed "The user"$username" not created."}
Else {Write-Host  -ForegroundColor Green "The user"$username" created successfully."}




$firstname = Read-Host -Prompt "Enter First Name"

}

Write-Host -ForegroundColor Red "Done, Thank You"

