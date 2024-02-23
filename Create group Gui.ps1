# Suppress progress bar
$ProgressPreference = 'SilentlyContinue'

$s=New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ex2019.alex.local/powershell 
Import-PSSession -session $s -AllowClobber  -DisableNameChecking | Out-Null

# Reset progress preference if needed
$ProgressPreference = 'Continue'

# A function to create the form
function Groups_Form {
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

    # Set the size of your form
    $Form = New-Object System.Windows.Forms.Form
    $Form.width = 500
    $Form.height = 350 # Increased height to accommodate new input field
    $Form.Text = "Groups Creation"

    # Set the font of the text to be used within the form
    $Font = New-Object System.Drawing.Font("Times New Roman",12)
    $Form.Font = $Font

    # Label for the group name text box
    $labelGroupName = New-Object System.Windows.Forms.Label
    $labelGroupName.Location = New-Object System.Drawing.Point(10,20)
    $labelGroupName.Size = New-Object System.Drawing.Size(280,20)
    $labelGroupName.Text = "Please enter a name:"
    $Form.Controls.Add($labelGroupName)

    # Text box for entering the group name
    $textBoxGroupName = New-Object System.Windows.Forms.TextBox
    $textBoxGroupName.Location = New-Object System.Drawing.Point(10,40)
    $textBoxGroupName.Size = New-Object System.Drawing.Size(260,20)
    $Form.Controls.Add($textBoxGroupName)

    # Label for the display name text box
    $labelDisplayName = New-Object System.Windows.Forms.Label
    $labelDisplayName.Location = New-Object System.Drawing.Point(10,70)
    $labelDisplayName.Size = New-Object System.Drawing.Size(280,20)
    $labelDisplayName.Text = "Please enter the display name:"
    $Form.Controls.Add($labelDisplayName)

    # Text box for entering the display name
    $textBoxDisplayName = New-Object System.Windows.Forms.TextBox
    $textBoxDisplayName.Location = New-Object System.Drawing.Point(10,90)
    $textBoxDisplayName.Size = New-Object System.Drawing.Size(260,20)
    $Form.Controls.Add($textBoxDisplayName)

    # Label to display the full email address
    $fullEmailLabel = New-Object System.Windows.Forms.Label
    $fullEmailLabel.Location = New-Object System.Drawing.Point(10,120)
    $fullEmailLabel.Size = New-Object System.Drawing.Size(280,20)
    $fullEmailLabel.Text = "Full email will be: "
    $Form.Controls.Add($fullEmailLabel)

    # Event handler for text change in the group name text box
    $textBoxGroupName.add_TextChanged({
        $fullEmailLabel.Text = "Full email will be: " + $textBoxGroupName.Text + "@alex.com"
    })

    # Group Box for Radio Buttons
    $MyGroupBox = New-Object System.Windows.Forms.GroupBox
    $MyGroupBox.Location = '10,150'
    $MyGroupBox.size = '460,100'
    $MyGroupBox.text = "What type of group do you want to create?"

    # Radio Buttons for Group Type Selection
    $RadioButton1 = New-Object System.Windows.Forms.RadioButton
    $RadioButton1.Location = '20,20'
    $RadioButton1.size = '420,20'
    $RadioButton1.Checked = $true
    $RadioButton1.Text = "Distribution List (DL)"

    $RadioButton2 = New-Object System.Windows.Forms.RadioButton
    $RadioButton2.Location = '20,40'
    $RadioButton2.size = '420,20'
    $RadioButton2.Checked = $false
    $RadioButton2.Text = "Security Group"

    # Add the Radio Buttons to the GroupBox
    $MyGroupBox.Controls.AddRange(@($RadioButton1, $RadioButton2))

    # OK Button
    $OKButton = New-Object System.Windows.Forms.Button
    $OKButton.Location = '10,260'
    $OKButton.Size = '100,40'
    $OKButton.Text = 'OK'
    $OKButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $Form.AcceptButton = $OKButton

    # Cancel Button
    $CancelButton = New-Object System.Windows.Forms.Button
    $CancelButton.Location = '120,260'
    $CancelButton.Size = '100,40'
    $CancelButton.Text = "Cancel"
    $CancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $Form.CancelButton = $CancelButton

    # Add controls to the Form
    $Form.Controls.AddRange(@($MyGroupBox, $OKButton, $CancelButton))

    # Display the Form
    $Form.Add_Shown({$Form.Activate()})
    $result = $Form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    $Name = $textBoxGroupName.Text
    $DisplayName = $textBoxDisplayName.Text

    if ($RadioButton1.Checked) {
        $DLPath = "OU=DL,OU=Alex,DC=alex,DC=local"
        # Command to create Distribution Group
        New-DistributionGroup -Name $Name -DisplayName $DisplayName -PrimarySmtpAddress "$Name@alex.com" -OrganizationalUnit $DLPath -SamAccountName $Name  | Out-Null
    } elseif ($RadioButton2.Checked) {
        $SecurityPath = "OU=Groups,OU=Alex,DC=alex,DC=local"
        # Command to create Security Group
        New-DistributionGroup -Name $Name -DisplayName $DisplayName -PrimarySmtpAddress "$Name@alex.com" -Type Security -OrganizationalUnit $SecurityPath -SamAccountName $Name | Out-Null
    }

    # Popup message indicating that the group has been created
    [void][System.Windows.Forms.MessageBox]::Show("Group '$Name' has been created successfully.")
} else {
    [void][System.Windows.Forms.MessageBox]::Show("Group creation cancelled.")
}
}

# Call the Groups_Form function to run the script
Groups_Form
