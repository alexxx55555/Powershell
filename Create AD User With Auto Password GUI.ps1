# Suppress progress bar
$ProgressPreference = 'SilentlyContinue'

# Import Exchange Module
$s = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ex2019.alex.local/powershell 
Import-PSSession -session $s -AllowClobber -DisableNameChecking | Out-Null

# Reset progress preference if needed
$ProgressPreference = 'Continue'

# Create a loop to allow creating multiple users
while ($true) {

# Include the assemblies for forms
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic
Add-Type -AssemblyName System.Drawing

#Define a function to check password policy
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
        $tokens = $AccountDisplayName.Split(",.-,_ #`t")
        foreach ($token in $tokens) {
            if (($token) -and ($Password -match "$token")) {
                return $false
            }
        }
    }

    return $true   
}

# Function to generate random characters
function Get-RandomCharacters($length, $characters) {
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}

# Function to scramble a string
function ScrambleString([string]$inputString){     
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
}

# Function to check if an employee number is available
function Get-AvailableEmployeeNumber {
    param(
        [int]$EmployeeNumber,
        [string[]]$AllNum
    )

    # Check if the employee number is already in use
    $existingUser = Get-ADUser -Filter {EmployeeNumber -eq $EmployeeNumber}
    if ($existingUser) {
       [void][System.Windows.Forms.MessageBox]::Show("EmployeeNumber '$EmployeeNumber' is already in use by $($existingUser.SamAccountName)", "Employee Number In Use")
       # Find the next available employee number
        while ($AllNum -contains $EmployeeNumber) {
            $EmployeeNumber++
        }
        # Show the next available number only if the initial choice is taken
        [void][System.Windows.Forms.MessageBox]::Show("Next available employee number is '$EmployeeNumber'", "Available Employee Number")
    }
    # If the employee number is available, do not show any message
    return $EmployeeNumber
}

# Function to check if a manager exists in Active Directory
function Check-ManagerInAD {
    param (
        [string]$managerUsername,
        [string]$managerFullName
    )

    if ($managerUsername) {
        $manager = Get-ADUser -Filter {SamAccountName -eq $managerUsername} -ErrorAction SilentlyContinue
        if ($manager) {
            return $manager
        }
    }

    if ($managerFullName) {
        $names = $managerFullName.Split(' ')
        # Check by GivenName (first name) and Surname (last name)
        if ($names.Count -eq 2) {
            $manager = Get-ADUser -Filter {GivenName -eq $names[0] -and Surname -eq $names[1]} -ErrorAction SilentlyContinue
            if ($manager) {
                return $manager
            }
        }
    }

    return $null
}

# Function to handle KeyPress events for textboxes
function Combined_KeyPress {
    param(
        [System.Object]$sender,
        [System.Windows.Forms.KeyPressEventArgs]$e
    )

    # Determine the source textbox
    $sourceTextBox = $sender.Name

    # Logic for Phone Number TextBox
    if ($sourceTextBox -eq 'PhoneLabelTextBox') {
        # Allow only digits, control characters, and the plus sign (+)
        if (-not [char]::IsDigit($e.KeyChar) -and -not [char]::IsControl($e.KeyChar) -and $e.KeyChar -ne '+') {
            $e.Handled = $true
        }
    }

    # Logic for Employee Number TextBox
    elseif ($sourceTextBox -eq 'EmployeeNumberTextBox') {
        # Allow only digits and control characters (like backspace)
        if (-not [char]::IsDigit($e.KeyChar) -and -not [char]::IsControl($e.KeyChar)) {
            $e.Handled = $true
        }
    }
}

# Function to check for the existence of a source user in Active Directory
function Check-SourceUserInAD {
    param (
        [string]$sourceUsername
    )

    if ($sourceUsername) {
        $sourceUser = Get-ADUser -Filter {SamAccountName -eq $sourceUsername} -ErrorAction SilentlyContinue
        if ($sourceUser) {
            return $sourceUser
        }
    }

    return $null
}

# User creation path
$ADPath = "OU=Users,OU=Alex,DC=alex,DC=local"

# GUI Windows code
$main_form = New-Object System.Windows.Forms.Form
$main_form.Text = 'AlexIT New User Creation'
$main_form.Width = 350
$main_form.Height = 400
$main_form.AutoSize = $true

# Set the form border style to FixedSingle to prevent resizing
$main_form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle

# Load and display the company logo
$img =  [System.Drawing.Image]::Fromfile('\\dc1\Applications\alex.jpg')
$companyLogo = New-Object System.Windows.Forms.PictureBox
$companyLogo.Width = $img.Size.Width
$companyLogo.Height = $img.Size.Height
$companyLogo.Image = $img
$main_form.controls.add($companyLogo)

# Define the width of labels, textboxes, and spacing between them
$labelsWidth = 100
$textboxWidth = 150
$spacing = 10

# Create a label for the First Name field
$firstNameLabel = New-Object System.Windows.Forms.Label
$firstNameLabel.Text = "First Name"
$firstNameLabel.Location = New-Object System.Drawing.Point(10, 90)
$firstNameLabel.AutoSize = $true
$main_form.Controls.Add($firstNameLabel)

# Create a textbox for entering the First Name
$firstNameTextBox = New-Object System.Windows.Forms.TextBox
$firstNameTextBox.Width = 100
$firstNameTextBox.Location = New-Object System.Drawing.Point(110, 90)
$main_form.Controls.Add($firstNameTextBox)

# Create a label for the Last Name field
$lastNameLabel = New-Object System.Windows.Forms.Label
$lastNameLabel.Text = "Last Name"
$lastNameLabel.Location = New-Object System.Drawing.Point(10, 120)
$lastNameLabel.AutoSize = $true
$main_form.Controls.Add($lastNameLabel)

# Create a textbox for entering the Last Name
$lastNameTextBox = New-Object System.Windows.Forms.TextBox
$lastNameTextBox.Width = 100
$lastNameTextBox.Location = New-Object System.Drawing.Point(110, 120)
$main_form.Controls.Add($lastNameTextBox)

# Create a label for the Job Title field
$jobTitleLabel = New-Object System.Windows.Forms.Label
$jobTitleLabel.Text = "Job Title"
$jobTitleLabel.Location = New-Object System.Drawing.Point(10, 150)
$jobTitleLabel.AutoSize = $true
$main_form.Controls.Add($jobTitleLabel)

# Create a textbox for entering the Job Title
$jobTitleTextBox = New-Object System.Windows.Forms.TextBox
$jobTitleTextBox.Width = 100
$jobTitleTextBox.Location = New-Object System.Drawing.Point(110, 150)
$main_form.Controls.Add($jobTitleTextBox)

# Create a label for the Manager field
$managerLabel = New-Object System.Windows.Forms.Label
$managerLabel.Text = "Manager"
$managerLabel.Location = New-Object System.Drawing.Point(10, 180)
$managerLabel.AutoSize = $true
$main_form.Controls.Add($managerLabel)

# Create a textbox for entering the Manager
$managerTextBox = New-Object System.Windows.Forms.TextBox
$managerTextBox.Width = 100
$managerTextBox.Location = New-Object System.Drawing.Point(110, 180)
$main_form.Controls.Add($managerTextBox)

# Create a label for the Phone field
$PhoneLabel = New-Object System.Windows.Forms.Label
$PhoneLabel.Text = "Phone"
$PhoneLabel.Location = New-Object System.Drawing.Point(10, 210)
$PhoneLabel.AutoSize = $true
$main_form.Controls.Add($PhoneLabel)

# Add a KeyPress event handler to restrict input using the Combined_KeyPress function
$PhoneLabelTextBox = New-Object System.Windows.Forms.TextBox
$PhoneLabelTextBox.Name = 'PhoneLabelTextBox'
$PhoneLabelTextBox.Width = 100
$PhoneLabelTextBox.Location = New-Object System.Drawing.Point(110, 210)
$PhoneLabelTextBox.Add_KeyPress({ Combined_KeyPress $args[0] $args[1] })
$main_form.Controls.Add($PhoneLabelTextBox)

# Create a label for the Employee Number field
$employeeNumberLabel = New-Object System.Windows.Forms.Label
$employeeNumberLabel.Text = "Employee number"
$employeeNumberLabel.Location = New-Object System.Drawing.Point(10, 240)
$employeeNumberLabel.AutoSize = $true
$main_form.Controls.Add($employeeNumberLabel)

# Create a textbox for entering the Employee Number
$EmployeeNumberTextBox = New-Object System.Windows.Forms.TextBox
$EmployeeNumberTextBox.Name = 'EmployeeNumberTextBox'
$EmployeeNumberTextBox.Width = 100
$EmployeeNumberTextBox.Location = New-Object System.Drawing.Point(110, 240)
# Add a KeyPress event handler to restrict input using the Combined_KeyPress function
$EmployeeNumberTextBox.Add_KeyPress({ Combined_KeyPress $args[0] $args[1] })
$main_form.Controls.Add($EmployeeNumberTextBox)

# Create a label for the Location field
$officeLocationLabel = New-Object System.Windows.Forms.Label
$officeLocationLabel.Text = "Location"
$officeLocationLabel.Location = New-Object System.Drawing.Point(10, 270)
$officeLocationLabel.AutoSize = $true
$main_form.Controls.Add($officeLocationLabel)

# Create a textbox for entering the Location
$officeLocationTextBox = New-Object System.Windows.Forms.TextBox
$officeLocationTextBox.Width = 100
$officeLocationTextBox.Location = New-Object System.Drawing.Point(110, 270)
$main_form.Controls.Add($officeLocationTextBox)

# Create a label for the "Copy groups from" field
$copyGroupsLabel = New-Object System.Windows.Forms.Label
$copyGroupsLabel.Text = "Copy groups from:"
$copyGroupsLabel.Location = New-Object System.Drawing.Point(10, 300)
$copyGroupsLabel.AutoSize = $true
$main_form.Controls.Add($copyGroupsLabel)

# Create a textbox for entering the source for copying groups
$copyGroupsTextBox = New-Object System.Windows.Forms.TextBox
$copyGroupsTextBox.Width = 100
$copyGroupsTextBox.Location = New-Object System.Drawing.Point(110, 300)
$main_form.Controls.Add($copyGroupsTextBox)

# Define Active Directory OUs and retrieve groups
$ouDNs = @("OU=Groups,OU=Alex,DC=alex,DC=local", "OU=DL,OU=Alex,DC=alex,DC=local")
$allGroups = foreach ($ouDN in $ouDNs) {
    Get-ADGroup -Filter "objectClass -eq 'group' -or objectClass -eq 'msExchDynamicDistributionList'" -SearchBase $ouDN
}

# Create the OK button
$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Point(10, 340)
$OKButton.Size = New-Object System.Drawing.Size(75, 23)
$OKButton.Text = 'Create User'
$OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$main_form.AcceptButton = $OKButton
$main_form.Controls.Add($OKButton)

# Create the Cancel button
$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(100, 340)
$CancelButton.Size = New-Object System.Drawing.Size(75, 23)
$CancelButton.Text = 'Cancel'
$CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$main_form.CancelButton = $CancelButton
$main_form.Controls.Add($CancelButton)

# Initialize variable to store the employee number
$employeeNumber = $null

# Retrieve all employee numbers from Active Directory before showing the form
$allEmployeeNumbers = Get-ADUser -Filter * -Properties EmployeeNumber | Select-Object -ExpandProperty EmployeeNumber

# Start of the manager verification loop
do {
    $managerFound = $false

    # Show GUI
    $result = $main_form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
        [System.Windows.Forms.MessageBox]::Show("New user creation cancelled!", "New User Creation Result", "Ok", "Information")
        exit
    }

    # Check for available employee number only if it hasn't been set
    if ($null -eq $employeeNumber) {
        $enteredEmployeeNumber = [int]$employeeNumberTextBox.Text
        $employeeNumber = Get-AvailableEmployeeNumber -EmployeeNumber $enteredEmployeeNumber -AllNum $allEmployeeNumbers
    }

    # Gather user input from the form
    $firstname = $firstNameTextBox.Text
    $lastname = $lastNameTextBox.Text
    $jobTitle = $jobTitleTextBox.Text
    $managerUsername = $managerTextBox.Text
    $officePhone = $PhoneLabelTextBox.Text
    $officeLocation = $officeLocationTextBox.Text
    $sourceUsername = $copyGroupsTextBox.Text

    # Check if any required fields are empty
    if ([string]::IsNullOrWhiteSpace($firstname) -or
        [string]::IsNullOrWhiteSpace($lastname) -or
        [string]::IsNullOrWhiteSpace($jobTitle) -or
        [string]::IsNullOrWhiteSpace($managerUsername) -or
        [string]::IsNullOrWhiteSpace($officePhone) -or
        [string]::IsNullOrWhiteSpace($officeLocation) -or
        [string]::IsNullOrWhiteSpace($sourceUsername) -or
        [string]::IsNullOrWhiteSpace($EmployeeNumberTextBox.Text)) {
        [void][System.Windows.Forms.MessageBox]::Show("All fields are required. Please fill in all details.", "Incomplete Details", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        continue
    }

    # Generate a random password 
    $password = Get-RandomCharacters -length 2 -characters 'abcdefghiklmnoprstuvwxyz'
    $password += Get-RandomCharacters -length 1 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
    $password += Get-RandomCharacters -length 1 -characters '1234567890'
    $password += Get-RandomCharacters -length 1 -characters '!"$%&/()=?}][{@#*+'

    # Set username
    $i = 1
    $basename = $firstname
    $username = $basename + $lastName.Substring(0,$i)
    $username = $username.ToLower()

    # Generate a unique username by appending a number if necessary
    while ((Get-ADUser -filter {SamAccountName -eq $username}).SamAccountName -eq $username){
        if($i -gt $lastName.Length){
            # update the basename and reset $i
            $basename = $username
            $i=1
        }
        $username = $baseName + $lastName.Substring(0,$i++)
        $username = $username.ToLower()
    }

    # Generate email addresses based on the username
    $email = $username + "@alex.com"

    # Check Manager in AD
    $manager = Check-ManagerInAD -managerUsername $managerUsername -managerFullName $managerFullName

    if ($null -eq $manager) {
        [void][System.Windows.Forms.MessageBox]::Show("Manager not found. Please check the manager's username or full name.", "Manager Not Found")
        # Reset the manager field for new input
        $managerTextBox.Text = ""
        continue
    } else {
        $managerFound = $true
    }
} while (-not $managerFound)

if ($null -eq $manager) {
    [System.Windows.Forms.MessageBox]::Show("Manager not found in Active Directory. Please check the manager's username or full name.", "Manager Not Found")
    return
}

if ($managerFound) {

    # Define common parameters for New-ADUser cmdlet
    $adUserParams = @{
        GivenName          = $firstname
        Surname            = $lastname
        EmployeeNumber     = $employeeNumber  
        Displayname        = "$FirstName $lastname"
        UserPrincipalName  = $email
        SamAccountName     = $username
        AccountPassword    = (ConvertTo-SecureString $password -AsPlainText -Force)
        Path               = $ADPath
        Office             = $officeLocation  
        OfficePhone        = $officePhone
        Enabled            = $true
        Title              = $jobTitle
        Manager            = $manager.DistinguishedName
    }

    # Check if the user already exists with the given first and last name
    $userExists = Get-ADUser -Filter "surname -eq '$lastname' -and givenname -eq '$firstname'"

    # Modify parameters if user exists
    if ($userExists) {
        $adUserParams['Name'] = "$firstname $lastname ($employeeNumber)"
    }
    else {
        $adUserParams['Name'] = "$firstname $lastname"
    }

    # Create the AD User
    New-ADUser @adUserParams

    # Initialize arrays to store copied groups
    $copiedDLGroups = @()
    $copiedSecurityGroups = @()

    # Retrieve the source username from the form
    $sourceUsername = $copyGroupsTextBox.Text
    $groupsCopied = $false

    # Loop until groups are copied
    while (-not $groupsCopied) {
        $sourceUser = Check-SourceUserInAD -sourceUsername $sourceUsername

        if ($null -eq $sourceUser) {
            [void][System.Windows.Forms.MessageBox]::Show("Source user '$sourceUsername' not found. Please check the name.", "Source User Not Found", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            $copyGroupsTextBox.Text = ""
            $result = $main_form.ShowDialog()

            if ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
                [System.Windows.Forms.MessageBox]::Show("New user creation cancelled!", "New User Creation Result", "Ok", "Information")
                exit
            }

            $sourceUsername = $copyGroupsTextBox.Text
        } else {
            $sourceUserGroups = Get-ADPrincipalGroupMembership -Identity $sourceUser

            foreach ($group in $sourceUserGroups) {
                if ($group.Name -ne "Domain Users") {
                    # Check if user is already a member of the group
                    $groupMembers = Get-ADGroupMember -Identity $group

                    if ($groupMembers | Where-Object { $_.SamAccountName -eq $username }) {
                        $null = "User $username is already a member of group $($group.SamAccountName). Skipping."
                    } else {
                        Add-ADGroupMember -Identity $group -Members $username -ErrorAction SilentlyContinue
                        $null = "User $username added to group $($group.SamAccountName)."

                        # Categorize the group as either DL or security
                        if ($group.groupCategory -eq 'Security') {
                            $copiedSecurityGroups += $group.Name
                        } elseif ($group.groupCategory -eq 'Distribution') {
                            $copiedDLGroups += $group.Name
                        }
                    }
                }
            }

            [void][System.Windows.Forms.MessageBox]::Show("Groups copied from $sourceUsername to $username.", "Group Copy Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

            $groupsCopied = $true
        }
    }

    # Show a message box with the generated password
    [void][System.Windows.Forms.MessageBox]::Show("The password for $username is: $password")

    # Create Mailbox
    Get-User -OrganizationalUnit alex.local/alex/users/ -RecipientTypeDetails user | Enable-Mailbox | Out-Null

    # Construct and display a detailed message to verify the new user's details
    $subject = "New Users Created"
    $Message = @"
    New User Created: 
    First Name: $firstname 
    Last Name: $lastname 
    Employee number: $employeeNumber
    Username: $username 
    Manager: $($manager.GivenName) $($manager.Surname)
    Office Location: $officeLocation 
    Office Phone: $officePhone 
    E-mail: $email 
    DL Groups Copied: $($copiedDLGroups -join ', ')
    Security Groups Copied: $($copiedSecurityGroups -join ', ')
    Initial Password: $password

    Make sure to save the initial password in a safe location!
"@

    $verifyDetails = [System.Windows.Forms.MessageBox]
    [void] $verifyDetails::Show($Message,"Verify New User Details","OK", "Information")
    
    # Send an email with user creation details
    $server = "EX2019.alex.local"
    $to = "vinokura@alex.com"
    $from = "ITRobot@alex.com"
    $subject = "New Users Created"

    $Body = @"
    <img src='\\dc1\Applications\alex.jpg' width='343' height='66'></img>

    <br>
    <p><b><h1><font color='blue'>New User Created:</b></p></h1></font> 
    <p><b><font color='black'><h4>First Name: $firstname </b></p></font></h4></b>
    <p><b><font color='black'><h4>Last Name: $lastname </b></p></font></h4></b>
    <p><b><font color='black'><h4>Employee Number: $employeeNumber </b></p></font></h4></b>
    <p><b><font color='black'><h4>Username: $username </b></p></font></h4></b>
    <p><b><font color='black'><h4>Manager: $($manager.GivenName) $($manager.Surname) </b></p></font></h4></b>
    <p><b><font color='black'><h4>Office Location: $officeLocation </b></p></font></h4></b>
    <p><b><font color='black'><h4>Office Phone: $officePhone </b></p></font></h4></b>
    <p><b><font color='black'><h4>E-mail: $email </b></p></font></h4></b>
    <p><b><font color='black'><h4>Groups: $($SelectedGroups -join ",")</b></p></font></h4></b>
    <p><b><font color='black'><h4>DL Groups Copied: $($copiedDLGroups -join ', ')</b></p></font></h4></b>
    <p><b><font color='black'><h4>Security Groups Copied: $($copiedSecurityGroups -join ', ')</b></p></font></h4></b>
    <p><b><font color='red'><h2>Make sure to save the initial password in a safe location!</b></p></font></h2></b>
    <p><b><font color='green'><h1>Alex IT</b></p></font></h1></b>
"@

    foreach ($username in $username){
        $message += "$($username.SamAccountName)     $($username.DisplayName)     $($username.emailaddress)
		"
    }

    # Send the email
    Send-MailMessage -To $to -From $from -Subject $subject -Body $Body -BodyAsHtml -SmtpServer $server

    # Check if user is created successfully or not Pop-Up                
    $User = Get-ADUser -LDAPFilter "(sAMAccountName=$username)"
    If ($Null -eq $User) {
        [void][System.Windows.Forms.MessageBox]::Show("The user $username not created", "Information")
    }
    Else {
        [void][System.Windows.Forms.MessageBox]::Show("The user $username created successfully!", "Information")
    }

    # Check if you want to create another user
    $createAnother = [System.Windows.Forms.MessageBox]::Show("Do you want to create another user?", "Question", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    if ($createAnother -eq "No") {
        [void][System.Windows.Forms.MessageBox]::Show("Done, Thank You", "Information")
        break
    } else {
        # Reset the form fields
        $firstNameTextBox.Text = ""
        $lastNameTextBox.Text = ""
        $jobTitleTextBox.Text = ""
        $managerTextBox.Text = ""
        $employeeNumberTextBox.Text = ""
        $officeLocationTextBox.Text = ""
        $PhoneLabelTextBox.Text = ""
        $copyGroupsTextBox.Text = ""
    }
}
}
# Close the form after exiting the loop 
$main_form.Close()
