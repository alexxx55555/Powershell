Import-Module ActiveDirectory

function Get-UsernamesFromAD {
    $ouDistinguishedName = "OU=Users,OU=Alex,DC=alex,DC=local"
    $users = Get-ADUser -Filter * -SearchBase $ouDistinguishedName -ResultSetSize 1000 | Select-Object -ExpandProperty SamAccountName
    return $users
}

# Load the Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Edit User Info"
$form.Width = 520
$form.Height = 520
$form.StartPosition = "CenterScreen"

# Create the form controls
$label1 = New-Object System.Windows.Forms.Label
$label1.Location = New-Object System.Drawing.Point(10, 20)
$label1.Size = New-Object System.Drawing.Size(100, 20)
$label1.Text = "Username:"
$form.Controls.Add($label1)

$usernameTextbox = New-Object System.Windows.Forms.TextBox
$usernameTextbox.Location = New-Object System.Drawing.Point(110, 20)
$usernameTextbox.Size = New-Object System.Drawing.Size(150, 20)
$form.Controls.Add($usernameTextbox)

# Add AutoComplete to the username textbox
$usernames = Get-UsernamesFromAD
$usernameTextbox.AutoCompleteMode = [System.Windows.Forms.AutoCompleteMode]::Suggest
$usernameTextbox.AutoCompleteSource = [System.Windows.Forms.AutoCompleteSource]::CustomSource
$usernameTextbox.AutoCompleteCustomSource = New-Object System.Windows.Forms.AutoCompleteStringCollection
$usernameTextbox.AutoCompleteCustomSource.AddRange($usernames)


$searchButton = New-Object System.Windows.Forms.Button
$searchButton.Location = New-Object System.Drawing.Point(270, 20)
$searchButton.Size = New-Object System.Drawing.Size(100, 20)
$searchButton.Text = "Search"
$form.Controls.Add($searchButton)


$searchButton.Add_Click({
    $username = $usernameTextbox.Text
    
    if ([string]::IsNullOrEmpty($username)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a username.")
    }
    else {
        try {
            $user = Get-ADUser -Identity $username -Properties DisplayName, Description, EmailAddress, Office, Title, TelephoneNumber, msRTCSIP-PrimaryUserAddress, Enabled, MemberOf,  EmployeeNumber, Manager 

            
            if ($user) {
                $fullNameTextbox.Text = $user.DisplayName
                $descriptionTextbox.Text = $user.Description
                $emailTextbox.Text = $user.EmailAddress
                $employeeNumberTextbox.Text = $user.EmployeeNumber         
                if ($user.Manager) {
    $manager = Get-ADUser -Identity $user.Manager -Properties DisplayName
    $managerName = $manager.DisplayName
    $managerTextbox.Text = $managerName
}
else {
    $managerTextbox.Text = ""
}
                $officeTextbox.Text = $user.Office
                $titleTextbox.Text = $user.Title
                $phoneTextbox.Text = $user.TelephoneNumber
                $sipTextbox.Text = $user."msRTCSIP-PrimaryUserAddress"
                $updateButton.Enabled = $true

                
                # Set the "Enable User" and "Disable User" checkboxes based on the user account status
                if ($user.Enabled) {
                    $enableCheckbox.Checked = $true
                    $disableCheckbox.Checked = $false
                }
                else {
                    $enableCheckbox.Checked = $false
                    $disableCheckbox.Checked = $true
                }
                
                $enableCheckbox.Enabled = $true
                $disableCheckbox.Enabled = $true
                
$groupMembership = Get-ADPrincipalGroupMembership $user
$distGroups = ($groupMembership | Where-Object { $_.GroupCategory -eq "Distribution" } | Select-Object -ExpandProperty Name) -join ', '
$secGroups = ($groupMembership | Where-Object { $_.GroupCategory -eq "Security" } | Select-Object -ExpandProperty Name) -join ', '
$distGroupsTextbox.Text = $distGroups
$secGroupsTextbox.Text = $secGroups

                
                # Enable all form controls
                $form.Controls | ForEach-Object {
                    $_.Enabled = $true
                }
            }
            else {
                [System.Windows.Forms.MessageBox]::Show("User not found.")
            }
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("User not found")
        }
    }
})

# Create the "Enable User" checkbox
$enableCheckbox = New-Object System.Windows.Forms.CheckBox
$enableCheckbox.Location = New-Object System.Drawing.Point(110, 400)
$enableCheckbox.Size = New-Object System.Drawing.Size(100, 20)
$enableCheckbox.Text = "Enable User"
$enableCheckbox.Enabled = $false
$form.Controls.Add($enableCheckbox)

# Create the "Disable User" checkbox
$disableCheckbox = New-Object System.Windows.Forms.CheckBox
$disableCheckbox.Location = New-Object System.Drawing.Point(220, 400)
$disableCheckbox.Size = New-Object System.Drawing.Size(100, 20)
$disableCheckbox.Text = "Disable User"
$disableCheckbox.Enabled = $false
$form.Controls.Add($disableCheckbox)

# Add event handlers for the checkboxes
$enableCheckbox.Add_CheckedChanged({
    if ($enableCheckbox.Checked) {
        $disableCheckbox.Checked = $false
    }
})

$disableCheckbox.Add_CheckedChanged({
    if ($disableCheckbox.Checked) {
        $enableCheckbox.Checked = $false
    }
})



$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(10, 50)
$label2.Size = New-Object System.Drawing.Size(100, 20)
$label2.Text = "Full Name:"
$form.Controls.Add($label2)

$fullNameTextbox = New-Object System.Windows.Forms.TextBox
$fullNameTextbox.Location = New-Object System.Drawing.Point(110, 50)
$fullNameTextbox.Size = New-Object System.Drawing.Size(260, 20)
$form.Controls.Add($fullNameTextbox)

$label3 = New-Object System.Windows.Forms.Label
$label3.Location = New-Object System.Drawing.Point(10, 350)
$label3.Size = New-Object System.Drawing.Size(100, 40)     
$label3.Text = "Description:"
$form.Controls.Add($label3)

$descriptionTextbox = New-Object System.Windows.Forms.TextBox
$descriptionTextbox.Location = New-Object System.Drawing.Point(110, 350)
$descriptionTextbox.Size = New-Object System.Drawing.Size(260, 20)     
$form.Controls.Add($descriptionTextbox)


$label10 = New-Object System.Windows.Forms.Label
$label10.Location = New-Object System.Drawing.Point(10, 200)
$label10.Size = New-Object System.Drawing.Size(100, 20)     
$label10.Text = "Manager:"
$form.Controls.Add($label10)

$managerTextbox = New-Object System.Windows.Forms.TextBox
$managerTextbox.Location = New-Object System.Drawing.Point(110, 200)
$managerTextbox.Size = New-Object System.Drawing.Size(260, 20)     
$form.Controls.Add($managerTextbox)


$label4 = New-Object System.Windows.Forms.Label
$label4.Location = New-Object System.Drawing.Point(10, 110)
$label4.Size = New-Object System.Drawing.Size(100, 20)
$label4.Text = "Email Address:"
$form.Controls.Add($label4)

$emailTextbox = New-Object System.Windows.Forms.TextBox
$emailTextbox.Location = New-Object System.Drawing.Point(110, 110)
$emailTextbox.Size = New-Object System.Drawing.Size(260, 20)
$emailTextbox.ReadOnly = $true  # Set the email textbox to read-only
$form.Controls.Add($emailTextbox)

$label5 = New-Object System.Windows.Forms.Label
$label5.Location = New-Object System.Drawing.Point(10, 260)
$label5.Size = New-Object System.Drawing.Size(100, 20)
$label5.Text = "Office:"
$form.Controls.Add($label5)

$officeTextbox = New-Object System.Windows.Forms.TextBox
$officeTextbox.Location = New-Object System.Drawing.Point(110, 260)
$officeTextbox.Size = New-Object System.Drawing.Size(260, 20)
$form.Controls.Add($officeTextbox)


$label6 = New-Object System.Windows.Forms.Label
$label6.Location = New-Object System.Drawing.Point(10, 170)
$label6.Size = New-Object System.Drawing.Size(100, 20)
$label6.Text = "Title:"
$form.Controls.Add($label6)


$label9 = New-Object System.Windows.Forms.Label
$label9.Location = New-Object System.Drawing.Point(10, 80)  
$label9.Size = New-Object System.Drawing.Size(100, 25)       
$label9.Text = "Employee Number:"
$form.Controls.Add($label9)

$employeeNumberTextbox = New-Object System.Windows.Forms.TextBox
$employeeNumberTextbox.Location = New-Object System.Drawing.Point(110, 80) 
$employeeNumberTextbox.Size = New-Object System.Drawing.Size(260, 20)         
$employeeNumberTextbox.ReadOnly = $true  # set ReadOnly property to true
$form.Controls.Add($employeeNumberTextbox)


$titleTextbox = New-Object System.Windows.Forms.TextBox
$titleTextbox.Location = New-Object System.Drawing.Point(110, 170)
$titleTextbox.Size = New-Object System.Drawing.Size(260, 20)
$form.Controls.Add($titleTextbox)

$label7 = New-Object System.Windows.Forms.Label
$label7.Location = New-Object System.Drawing.Point(10, 140)
$label7.Size = New-Object System.Drawing.Size(100, 20)
$label7.Text = "Phone number:"
$form.Controls.Add($label7)

$phoneTextbox = New-Object System.Windows.Forms.TextBox
$phoneTextbox.Location = New-Object System.Drawing.Point(110, 140)
$phoneTextbox.Size = New-Object System.Drawing.Size(260, 20)

# Add the event handler to allow only digits, backspace, delete, and numeric keys in the phone number textbox
$phoneTextbox.add_KeyDown({
    $keyCode = $_.KeyCode

    # Allow digits, backspace, delete, numeric keys, and arrow keys
    if ($keyCode -ge 'D0' -and $keyCode -le 'D9' -or 
        $keyCode -eq 'Back' -or $keyCode -eq 'Delete' -or
        ($keyCode -ge 'NumPad0' -and $keyCode -le 'NumPad9') -or
        ($keyCode -ge 'Left' -and $keyCode -le 'Down')) {
        return
    }
    else {
        $_.SuppressKeyPress = $true
    }
})

$form.Controls.Add($phoneTextbox)

$label8 = New-Object System.Windows.Forms.Label
$label8.Location = New-Object System.Drawing.Point(10, 230)
$label8.Size = New-Object System.Drawing.Size(100, 20)
$label8.Text = "SIP Address:"
$form.Controls.Add($label8)

$sipTextbox = New-Object System.Windows.Forms.TextBox
$sipTextbox.Location = New-Object System.Drawing.Point(110, 230)
$sipTextbox.Size = New-Object System.Drawing.Size(260, 20)
$sipTextbox.ReadOnly = $true
$form.Controls.Add($sipTextbox)

$label12 = New-Object System.Windows.Forms.Label
$label12.Location = New-Object System.Drawing.Point(10, 320)
$label12.Size = New-Object System.Drawing.Size(100, 20)
$label12.Text = "Distribution Group:"
$form.Controls.Add($label12)

$distGroupsTextbox = New-Object System.Windows.Forms.TextBox
$distGroupsTextbox.Location = New-Object System.Drawing.Point(110, 320)
$distGroupsTextbox.Size = New-Object System.Drawing.Size(260, 20)
$distGroupsTextbox.ReadOnly = $true
$form.Controls.Add($distGroupsTextbox)


$label11 = New-Object System.Windows.Forms.Label
$label11.Location = New-Object System.Drawing.Point(10, 290)
$label11.Size = New-Object System.Drawing.Size(100, 20)
$label11.Text = "Security Groups:"
$form.Controls.Add($label11)

$secGroupsTextbox = New-Object System.Windows.Forms.TextBox
$secGroupsTextbox.Location = New-Object System.Drawing.Point(110, 290)
$secGroupsTextbox.Size = New-Object System.Drawing.Size(260, 20)
$secGroupsTextbox.ReadOnly = $true
$form.Controls.Add($secGroupsTextbox)

# Disable all form controls
$form.Controls | ForEach-Object {
    $_.Enabled = $false
}
$usernameTextbox.Enabled = $true
$searchButton.Enabled = $true
$fullNameTextbox.Text = ""
$descriptionTextbox.Text = ""
$emailTextbox.Text = ""
$officeTextbox.Text = ""
$titleTextbox.Text = ""
$phoneTextbox.Text = ""
$sipTextbox.Text = ""



$updateButton = New-Object System.Windows.Forms.Button
$updateButton.Location = New-Object System.Drawing.Point(100, 430)
$updateButton.Size = New-Object System.Drawing.Size(100, 30)
$updateButton.Text = "Update"
$updateButton.Enabled = $false


$updateButton.Add_Click({
    $username = $usernameTextbox.Text
    
    if ([string]::IsNullOrEmpty($username)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a username.")
    }
    else {
        try {
            $user = Get-ADUser -Identity $username -Properties DisplayName, Description, EmailAddress, Office, Title, TelephoneNumber, msRTCSIP-PrimaryUserAddress, Enabled, MemberOf, EmployeeNumber, Manager
            
            if ($user) {
                $params = @{
                    'Identity' = $user
                }
                
                $userDisplayName = $fullNameTextbox.Text
                $userDescription = $descriptionTextbox.Text
                $userEmail = $emailTextbox.Text
                $userEmployeeNumber = $employeeNumberTextbox.Text
                $userManager = $managerTextbox.Text
                $userOffice = $officeTextbox.Text
                $userTitle = $titleTextbox.Text
                $userPhone = $phoneTextbox.Text
                $userSIP = $sipTextbox.Text
                
                if (![string]::IsNullOrEmpty($userDisplayName)) {
                    $params.Add('DisplayName', $userDisplayName)
                }
                
                if (![string]::IsNullOrEmpty($userDescription)) {
                    $params.Add('Description', $userDescription)
                }
                
                if (![string]::IsNullOrEmpty($userEmail)) {
                    $params.Add('EmailAddress', $userEmail)
                }
                
                if (![string]::IsNullOrEmpty($userEmployeeNumber)) {
                    $params.Add('EmployeeNumber', $userEmployeeNumber)
                }
                
                if (![string]::IsNullOrEmpty($userOffice)) {
                    $params.Add('Office', $userOffice)
                }
                
                if (![string]::IsNullOrEmpty($userTitle)) {
                    $params.Add('Title', $userTitle)
                }
                
                if (![string]::IsNullOrEmpty($userPhone)) {
                    $params.Add('OfficePhone', $userPhone)
                }
                
                if ($enableCheckbox.Checked) {
                    $params.Add('Enabled', $true)
                }
                
                if ($disableCheckbox.Checked) {
                    $params.Add('Enabled', $false)
                }
                
                if ($distGroups) {
                    $params.Add('MemberOf', $distGroups)
                }
                
                if ($secGroups) {
                    $params.Add('MemberOf', $secGroups)
                }
                
                # Check if the Manager field needs to be updated
                if (![string]::IsNullOrEmpty($userManager) -and $userManager -ne $user.Manager) {
                    $newManager = Get-ADUser -Filter "DisplayName -eq '$userManager' -or SamAccountName -eq '$userManager'" -Properties DisplayName, SamAccountName, DistinguishedName -ErrorAction Stop
                    if (!$newManager) {
                        [System.Windows.Forms.MessageBox]::Show("Manager not found.")
                        return
                    }
                    $params.Add('Manager', $newManager.DistinguishedName)
                }
                
                Set-ADUser @params
                [System.Windows.Forms.MessageBox]::Show("User information updated successfully.")
            }
            else {
                [System.Windows.Forms.MessageBox]::Show("User not found.")
            }
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            [System.Windows.Forms.MessageBox]::Show("The user entered in the Manager field was not found.")
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show($_.Exception.Message)
        }
    }
})




# Add the "Update" button to the form
$form.Controls.Add($updateButton)

# Add the "Cancel" button to the form
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(220,430)
$cancelButton.Size = New-Object System.Drawing.Size(100, 30)
$cancelButton.Text = "Cancel"
$cancelButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($cancelButton)

# Add the "Reset" button to the form
$resetButton = New-Object System.Windows.Forms.Button
$resetButton.Location = New-Object System.Drawing.Point(340, 430)
$resetButton.Size = New-Object System.Drawing.Size(100, 30)
$resetButton.Text = "Reset"
$resetButton.Add_Click({
    if ($usernameTextbox.Text -eq "") {
        [System.Windows.Forms.MessageBox]::Show("It not possible to reset empty form.")
    }
    else {
        $form.Controls | ForEach-Object {
            $_.Enabled = $false
        }
        $usernameTextbox.Enabled = $true
        $searchButton.Enabled = $true

        # Clear all form fields
        $usernameTextbox.Text = ""
        $fullNameTextbox.Text = ""
        $descriptionTextbox.Text = ""
        $emailTextbox.Text = ""
        $officeTextbox.Text = ""
        $titleTextbox.Text = ""
        $phoneTextbox.Text = ""
        $distGroupsTextbox.Text = ""
        $managerTextbox.Text = ""
        $employeeNumberTextbox.Text = ""
        $secGroupsTextbox.Text = "" 
        $sipTextbox.Text = ""
        $enableCheckbox.Checked = $false
        $disableCheckbox.Checked = $false
        $enableCheckbox.Enabled = $false
        $disableCheckbox.Enabled = $false
        $updateButton.Enabled = $false
    }
})
$form.Controls.Add($resetButton)

# Display the form
$form.ShowDialog() | Out-Null


