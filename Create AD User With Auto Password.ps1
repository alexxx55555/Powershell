﻿Import-Module ActiveDirectory
Add-Type -AssemblyName System.Windows.Forms

#Check Password Policy
Function Test-PasswordForDomain {
    Param (
        [Parameter(Mandatory=$true)][SecureString]$Password,
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
    $tokens = $AccountDis
    playName.Split(",.-,_ #`t")
    foreach ($token in $tokens) {
        if (($token) -and ($Password -match "$token")) {
            return $false
        }
    }
}
   
   
    return $true   
   
}

function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}

function ScrambleString([string]$inputString){     
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
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
Import-PSSession -session $s -AllowClobber  -DisableNameChecking


#Import SFB Module
$pass = Get-Content "C:\test\Password.txt" | ConvertTo-SecureString
$user = “vinokura”
$Credentials = new-object -typename System.Management.Automation.PSCredential -argumentlist $user, $pass


$SkypeSession = New-PSSession -Credential $Credentials -ConnectionURI https://Skype-Server.alex.local/OcsPowershell 
Import-PSSession $SkypeSession -AllowClobber  -DisableNameChecking



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
            $EmployeeNumber = [int](Read-Host "Enter Employee Number")
            If ( $EmployeeNumber.ToString().Length -le 3) {
                $EmpNumOK = $true
            }
   
            Else {
   
                [void][System.Windows.Forms.MessageBox]::Show("Length of $($EmployeeNumber.ToString().Length) digits is invalid for employee number, please use up to 3 digits.")

            }
       
 
        }


       
    }
    catch [System.Management.Automation.RuntimeException] {
      [void][System.Windows.Forms.MessageBox]::Show("You can only use numbers!")
       
       $EmployeeNumber = ""
    }
}
until (($EmployeeNumber -or $EmployeeNumber -eq 0) -and ($EmployeeNumber -match "^[0-9]*$" -and  $EmployeeNumber.ToString().Length -le 3))



    $allNum = 
    [Int32[]]($((Get-ADUser -Filter * -Properties EmployeeNumber).EmployeeNumber)) |
    Sort-Object -Descending 

    $newNum = Get-AvailableEmployeeNumber -EmployeeNumber $EmployeeNumber -AllNum $allNum
    if($newNum -ne $EmployeeNumber){
    
       
        [void][System.Windows.Forms.MessageBox]::Show("EmployeeNumber '$EmployeeNumber' is already in use by $((Get-ADUser -Filter {EmployeeNumber -eq $EmployeeNumber}).SamAccountName)")
    }
     [void][System.Windows.Forms.MessageBox]::Show("Employee number'$newNum' is Available")
    

$validPhoneNumber = $false
while (-not $validPhoneNumber) {
    $officePhone = Read-Host -Prompt "Enter Office Phone Number (10 digits)"
    if ($officePhone -match '^\d{10}$') {
        $validPhoneNumber = $true
    } else {
        [void][System.Windows.Forms.MessageBox]::Show("Invalid phone number. Please enter a 10-digit phone number.")
    }
}

$office = Read-Host -Prompt "Enter Office Location"

$jobTitle = Read-Host -Prompt "Enter Job Title"

$manager = $null
while (-not $manager) {
    $managerUsername = Read-Host -Prompt "Enter Manager's Username"
    $manager = Get-ADUser -Filter {SamAccountName -eq $managerUsername}
    if (-not $manager) {
        [void][System.Windows.Forms.MessageBox]::Show("Manager not found. Please check the username and try again.")
    }
}


$password = Get-RandomCharacters  -length 2 -characters 'abcdefghiklmnoprstuvwxyz'
$password += Get-RandomCharacters -length 1 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
$password += Get-RandomCharacters -length 1 -characters '1234567890'
$password += Get-RandomCharacters -length 1 -characters '!"$%&/()=?}][{@#*+'  

      

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

$email = $username + "@alex.com" 
$SFB = $username + "@alex.local" 

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
-Title $jobTitle `
-Office $office `
-OfficePhone $officePhone `
-Enabled 1 `
-Manager $manager.DistinguishedName
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
-Title $jobTitle `
-Office $office `
-OfficePhone $officePhone `
-Enabled 1 `
-Manager $manager.DistinguishedName
}

#Copy Groups

$SourceUser = $null
# create message to apply to read-host prompt

$Message = "Copy Groups From"
While (!$SourceUser) {
    $copyfrom = Read-Host -Prompt $Message
    Try {
        $SourceUser = Get-ADUser -Identity $copyfrom -Properties memberof -ErrorAction Stop
    } Catch {
        # Update message for retries
        $Message = "User not found. Please enter a user to copy groups from"
    }
}
$Result = $SourceUser.memberof | Add-ADGroupMember -Members $username -PassThru 


 [void][System.Windows.Forms.MessageBox]::Show("The password for $username is: $password")



# Create Mailbox
Get-User -OrganizationalUnit alex.local/alex/users -RecipientTypeDetails user | Enable-Mailbox

# Create SFB Account
Enable-CsUser -Identity $username -RegistrarPool "Skype-Server.alex.local" -SipAddressType SamAccountName -SipDomain "alex.local" 

#Message Popup

  $subject = "New Users Created"
    $Message =
    "New User Created: 
    First Name: $firstname 
    Last Name: $lastname 
    Employess number: $newNum 
    Username: $username 
    Title: $jobTitle 
    Manager: $($manager.GivenName) $($manager.Surname)
    Office Location: $office 
    OfficePhone: $officePhone 
    E-mail: $email 
    Sip: $SFB
    DL Groups: $($Result.Where({$_.groupcategory -eq 'distribution'}).name -join ',')
    Security Groups: $($Result.Where({$_.groupcategory -eq 'security'}).name-join ',')
    Initial Password: $password

    Make sure to save the initial password in a safe location!
    "

   $verifyDetails = [System.Windows.Forms.MessageBox]

   [void] $verifyDetails::Show($Message,"Verify New User Details","OK", "Information")
    

   
 
#Send Email
 
    $server = "EX2019.alex.local"
    $to = "vinokura@alex.com"
    $from = "ITRobot@alex.com"
    $subject = "New Users Created"

    $Body="

    <img src='\\dc1\Applications\alex.jpg' width='343' height='66'></img>

<br>
    <p><b><h1><font color='blue'>New User Created:</b></p></h1></font> 
    <p><b><font color='black'><h4>First Name: $firstname </b></p></font></h4></b>
    <p><b><font color='black'><h4>Last Name: $lastname </b></p></font></h4></b>
    <p><b><font color='black'><h4>Employess number: $newNum </b></p></font></h4></b>
    <p><b><font color='black'><h4>Username: $username </b></p></font></h4></b>
    <p><b><font color='black'><h4>Title: $jobTitle </b></p></font></h4></b>
    <p><b><font color='black'><h4>Manager: $($manager.GivenName) $($manager.Surname) </b></p></font></h4></b>
    <p><b><font color='black'><h4>Office Location: $office </b></p></font></h4></b>
    <p><b><font color='black'><h4>OfficePhone: $officePhone </b></p></font></h4></b>
    <p><b><font color='black'><h4>E-mail: $email </b></p></font></h4></b>
    <p><b><font color='black'><h4>Sip: $SFB</b></p></font></h4></b>
    <p><b><font color='black'><h4>Groups: $($SelectedGroups -join ",")</b></p></font></h4></b>
    <p><b><font color='black'><h4>DL Groups: $($Result.Where({$_.groupcategory -eq 'distribution'}).name -join ',')</b></p></font></h4></b>
    <p><b><font color='black'><h4>Security Groups: $($Result.Where({$_.groupcategory -eq 'security'}).name-join ',')</b></p></font></h4></b>
    <p><b><font color='black'><h4>Initial Password: $password</b></p></font></h4></b>
   

    <p><b><font color='red'><h2>Make sure to save the initial password in a safe location!</b></p></font></h2></b>

    <p><b><font color='green'><h1>Alex IT</b></p></font></h1></b>

    "

    forEach ($useraname in $username){
        $message += "$($username.SamAccountName)     $($username.DisplayName)     $($username.emailaddress)
		"
    

    Send-MailMessage -To $to -From $from -Subject $subject -Body $Body -BodyAsHtml -SmtpServer $server
             
               

#Check if user is creted successfully or not Pop-Up                
            

$User = Get-ADUser -LDAPFilter "(sAMAccountName=$username)"
If ($Null -eq $User) {[void] [System.Windows.Forms.MessageBox]::Show("The user $username not created", "Information") }
Else { [void][System.Windows.Forms.MessageBox]::Show("The user $username created successfully!", "Information")}
            
           
        }




$firstname = Read-Host -Prompt "Enter First Name"
}
 [void][System.Windows.Forms.MessageBox]::Show(" Done, Thank You")


