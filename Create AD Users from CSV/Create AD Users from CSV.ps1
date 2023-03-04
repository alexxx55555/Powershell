
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) `
{ Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }


# Get domain DNS suffix
$dnsroot = '@' + (Get-ADDomain).dnsroot
$defpassword = (ConvertTo-SecureString "12345" -AsPlainText -force)
# Import the file with the users. You can change the filename to reflect your file
$users = Import-Csv 'C:\AD User\users.csv'

foreach ($user in $users) {
        if ($user.manager -eq "") # In case it's a service account or a boss
            {
                try {
                    New-ADUser -SamAccountName $user.SamAccountName -Name ($user.FirstName + " " + $user.LastName) `
                    -DisplayName ($user.FirstName + " " + $user.LastName) -GivenName $user.FirstName -Surname $user.LastName `
                    -EmailAddress ($user.SamAccountName + $dnsroot) -UserPrincipalName ($user.SamAccountName + $dnsroot) `
                    -Title $user.title -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires  $false `
                    -AccountPassword $defpassword -PassThru `
                    -Path "OU=Users,OU=Alex,DC=alex,DC=local" `
                    }
                catch [System.Object]
                    {
                        Write-Output "Could not create user $($user.SamAccountName), $_"
                    }
            }
            else
             {
                try {
                    New-ADUser -SamAccountName $user.SamAccountName -Name ($user.FirstName + " " + $user.LastName) `
                    -DisplayName ($user.FirstName + " " + $user.LastName) -GivenName $user.FirstName -Surname $user.LastName `
                    -EmailAddress ($user.SamAccountName + $dnsroot) -UserPrincipalName ($user.SamAccountName + $dnsroot) `
                    -Title $user.title -manager $user.manager `
                    -Enabled $true -ChangePasswordAtLogon $false -PasswordNeverExpires  $false `
                    -AccountPassword $defpassword -PassThru `
                    -Path "OU=Users,OU=Alex,DC=alex,DC=local" `
                    }
                catch [System.Object]
                    {
                        Write-Output "Could not create user $($user.SamAccountName), $_"
                    }
             }
       
            }