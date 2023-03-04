# Import Exchange Module
$s=New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ex2019.alex.local/powershell 
Import-PSSession -session $s -AllowClobber

# Import SFB Module
$SkypeSession = New-PSSession -Credential $Credentials -ConnectionURI https://Skype-Server.alex.local/OcsPowershell 
Import-PSSession $SkypeSession -AllowClobber


$ADPath = "OU=Users,OU=Alex,DC=alex,DC=local"   

$firstname = Read-Host -Prompt "Enter First Name"
# Stop by empty first name
while (!($firstname -eq "")){

$lastname  = Read-Host -Prompt "Enter Last Name"
do {
    try {
        [int]$EmployeeNumber = Read-Host -Prompt "Enter Employee Number"
    }
    catch [System.Management.Automation.PSInvalidCastException] {
        Write-Host -ForegroundColor Red "You can only use numbers!!!"
    }
} while ($EmployeeNumber -isnot [int])
$password  = Read-Host -Prompt "Enter Password"

$dn = "CN=$firstname $lastname,$ADPath"

try {
    Get-ADUser -Identity $dn
    $name = "$firstname  $lastname ($EmployeeNumber)"
}
catch{
    $name = "$firstname $lastname"
}

$i = 1
$username = "$firstName$($lastName.Substring(0,$i))"
$username = $username.ToLower()

while ((Get-ADUser -filter {SamAccountName -eq $username}).SamAccountName -eq $username) {
    $username = "$firstName$($lastName.Substring(0,$i++))"
    $username = $username.ToLower()
}

$email = "$username@alex.local"

$params = @{
    Name              = $name
    GivenName         = $firstname 
    Surname           = $lastname 
    Displayname       = $name
    UserPrincipalName = $email
    SamAccountName    = $username  
    AccountPassword   = (ConvertTo-SecureString $password -AsPlainText -Force)
    Path              = $ADPath 
    Enabled           = $true 
}
New-ADUser @params

# Create Mailbox
Get-User -OrganizationalUnit alex.local/alex/users -RecipientTypeDetails user | Enable-Mailbox

# Create SFB Account
Get-CsAdUser -Ou "alex.local/alex/users" -Filter `
{Enabled -ne $false} | Enable-CsUser -RegistrarPool "Skype-Server.alex.local" -SipAddressType SamAccountName -SipDomain "alex.local" 
Get-CsAdUser -OU "alex.local/alex/users" -Filter {Enabled -ne $false} | Measure-Object | FL Count 
Write-Host  -ForegroundColor Green "The user"$username" created successfully."


$firstname = Read-Host -Prompt "Enter First Name"
}
Write-Host -ForegroundColor Red "Done, Thank You"