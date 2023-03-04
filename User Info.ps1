# Load the Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Edit User Info"
$form.Width = 500
$form.Height = 400
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
            $user = Get-ADUser -Identity $username -Properties DisplayName, Description, EmailAddress, Office, Title, TelephoneNumber, msRTCSIP-PrimaryUserAddress, Enabled, MemberOf
            
            if ($user) {
                $fullNameTextbox.Text = $user.DisplayName
                $descriptionTextbox.Text = $user.Description
                $emailTextbox.Text = $user.EmailAddress
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
                
                $groups = ($user.MemberOf | ForEach-Object {($_ -split ',')[0].Substring(3)}) -join ', '
                $groupsTextbox.Text = $groups
                
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
$label3.Location = New-Object System.Drawing.Point(10, 80)
$label3.Size = New-Object System.Drawing.Size(100, 20)
$label3.Text = "Description:"
$form.Controls.Add($label3)

$descriptionTextbox = New-Object System.Windows.Forms.TextBox
$descriptionTextbox.Location = New-Object System.Drawing.Point(110, 80)
$descriptionTextbox.Size = New-Object System.Drawing.Size(260, 20)
$form.Controls.Add($descriptionTextbox)

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
$label5.Location = New-Object System.Drawing.Point(10, 140)
$label5.Size = New-Object System.Drawing.Size(100, 20)
$label5.Text = "Office:"
$form.Controls.Add($label5)

$officeTextbox = New-Object System.Windows.Forms.TextBox
$officeTextbox.Location = New-Object System.Drawing.Point(110, 140)
$officeTextbox.Size = New-Object System.Drawing.Size(260, 20)
$form.Controls.Add($officeTextbox)

$label6 = New-Object System.Windows.Forms.Label
$label6.Location = New-Object System.Drawing.Point(10, 170)
$label6.Size = New-Object System.Drawing.Size(100, 20)
$label6.Text = "Title:"
$form.Controls.Add($label6)


$titleTextbox = New-Object System.Windows.Forms.TextBox
$titleTextbox.Location = New-Object System.Drawing.Point(110, 170)
$titleTextbox.Size = New-Object System.Drawing.Size(260, 20)
$form.Controls.Add($titleTextbox)

$label7 = New-Object System.Windows.Forms.Label
$label7.Location = New-Object System.Drawing.Point(10, 200)
$label7.Size = New-Object System.Drawing.Size(100, 20)
$label7.Text = "Phone Number:"
$form.Controls.Add($label7)

$phoneTextbox = New-Object System.Windows.Forms.TextBox
$phoneTextbox.Location = New-Object System.Drawing.Point(110, 200)
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

$label9 = New-Object System.Windows.Forms.Label
$label9.Location = New-Object System.Drawing.Point(10, 260)
$label9.Size = New-Object System.Drawing.Size(100, 20)
$label9.Text = "Groups:"
$form.Controls.Add($label9)

$groupsTextbox = New-Object System.Windows.Forms.TextBox
$groupsTextbox.Location = New-Object System.Drawing.Point(110, 260)
$groupsTextbox.Size = New-Object System.Drawing.Size(260, 20)
$groupsTextbox.ReadOnly = $true
$form.Controls.Add($groupsTextbox)

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
$groupsTextbox.Text = ""



# Enable the "Search" button and the "Username" textbox
$searchButton.Enabled = $true
$usernameTextbox.Enabled = $true

# Create the "Enable User" checkbox
$enableCheckbox = New-Object System.Windows.Forms.CheckBox
$enableCheckbox.Location = New-Object System.Drawing.Point(110, 290)
$enableCheckbox.Size = New-Object System.Drawing.Size(100, 20)
$enableCheckbox.Text = "Enable User"
$enableCheckbox.Enabled = $false
$form.Controls.Add($enableCheckbox)

# Create the "Disable User" checkbox
$disableCheckbox = New-Object System.Windows.Forms.CheckBox
$disableCheckbox.Location = New-Object System.Drawing.Point(220, 290)
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


$updateButton = New-Object System.Windows.Forms.Button
$updateButton.Location = New-Object System.Drawing.Point(100, 310)
$updateButton.Size = New-Object System.Drawing.Size(100, 30)
$updateButton.Text = "Update"
$updateButton.Enabled = $false
$updateButton.Add_Click({
    $username = $usernameTextbox.Text
    $fullName = $fullNameTextbox.Text
    $description = $descriptionTextbox.Text
    $email = $emailTextbox.Text
    $office = $officeTextbox.Text
    $title = $titleTextbox.Text
    $phone = $phoneTextbox.Text
    $sip = $sipTextbox.Text

    $user = Get-ADUser -Identity $username
    if ($user) {
        $params = @{
            'Identity' = $user
        }

        if ($fullName) {
            $params.Add('DisplayName', $fullName)
        }

        if ($description) {
            $params.Add('Description', $description)
        }

        if ($email) {
            $params.Add('EmailAddress', $email)
        }

        if ($office) {
            $params.Add('Office', $office)
        }

        if ($title) {
            if ($user.Title) {
                $params.Add('Title', $title)
            } else {
                $params.Add('Title', $title)
            }
        }

        if ($phone) {
            if ($user.OfficePhone) {
                $params.Add('OfficePhone', $user.OfficePhone + ', ' + $phone)
            }
            else {
                $params.Add('OfficePhone', $phone)
            }
        }

        if ($enableCheckbox.Checked) {
            $params.Add('Enabled', $true)
        }

        if ($disableCheckbox.Checked) {
            $params.Add('Enabled', $false)
        }

        Set-ADUser @params
        [System.Windows.Forms.MessageBox]::Show("User info updated successfully.")
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("User not found.")
    }
})




# Add the "Update" button to the form
$form.Controls.Add($updateButton)

# Add the "Cancel" button to the form
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(220,310)
$cancelButton.Size = New-Object System.Drawing.Size(100, 30)
$cancelButton.Text = "Cancel"
$cancelButton.Add_Click({
    $form.Close()
})
$form.Controls.Add($cancelButton)

# Add the "Reset" button to the form
$resetButton = New-Object System.Windows.Forms.Button
$resetButton.Location = New-Object System.Drawing.Point(340, 310)
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
        $sipTextbox.Text = ""
        $groupsTextbox.Text = ""
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

