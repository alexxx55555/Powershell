#$s=New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ex2019.alex.local/powershell 
#Import-PSSession -session $s -AllowClobber  -DisableNameChecking

# A function to create the form
function Groups_Form{
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
   
    # Set the size of your form
    $Form = New-Object System.Windows.Forms.Form
    $Form.width = 500
    $Form.height = 300
    $Form.Text = "Groups Creation"
 
    # Set the font of the text to be used within the form
    $Font = New-Object System.Drawing.Font("Times New Roman",12)
    $Form.Font = $Font

    # Create a group that will contain your radio buttons
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(45,20)
    $label.Size = New-Object System.Drawing.Size(280,20)
    $label.Text = "What type of group you want to create?"
    $form.Controls.Add($label)

    $MyGroupBox = New-Object System.Windows.Forms.GroupBox
    $MyGroupBox.Location = '50,40'
    $MyGroupBox.size = '380,110'
    
   
    # Create the collection of radio buttons
    $RadioButton1 = New-Object System.Windows.Forms.RadioButton
    $RadioButton1.Location = '20,40'
    $RadioButton1.size = '350,20'
    $RadioButton1.Checked = $true
    $RadioButton1.Text = "DL"
 
    $RadioButton2 = New-Object System.Windows.Forms.RadioButton
    $RadioButton2.Location = '20,70'
    $RadioButton2.size = '350,20'
    $RadioButton2.Checked = $false
    $RadioButton2.Text = "Secuirty"
 
 
    # Add an OK button
    $OKButton = new-object System.Windows.Forms.Button
    $OKButton.Location = '130,200'
    $OKButton.Size = '100,40'
    $OKButton.Text = 'Ok'
    $OKButton.DialogResult=[System.Windows.Forms.DialogResult]::OK
 
    #Add a cancel button
    $CancelButton = new-object System.Windows.Forms.Button
    $CancelButton.Location = '255,200'
    $CancelButton.Size = '100,40'
    $CancelButton.Text = "Cancel"
    $CancelButton.DialogResult=[System.Windows.Forms.DialogResult]::Cancel
 
    # Add all the GroupBox controls on one line
    $MyGroupBox.Controls.AddRange(@($Radiobutton1,$RadioButton2))
 
    # Add all the Form controls on one line
    $form.Controls.AddRange(@($MyGroupBox,$OKButton,$CancelButton))
 
 
   
    # Assign the Accept and Cancel options in the form to the corresponding buttons
    $form.AcceptButton = $OKButton
    $form.CancelButton = $CancelButton
 
    # Activate the form
    $form.Add_Shown({$form.Activate()})    
   
    # Get the results from the button click
    $dialogResult = $form.ShowDialog()

 if ($Form.DialogResult -eq 'Cancel') {
    [void][System.Windows.Forms.MessageBox]::Show("New group creation cancelled!")
}
    # If the OK button is selected
    if ($dialogResult -eq "OK"){
       
        # Check the current state of each radio button and respond accordingly
   $form = New-Object System.Windows.Forms.Form
$form.Text = 'Enter a Group Name'
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(75,120)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(150,120)
$cancelButton.Size = New-Object System.Drawing.Size(75,23)
$cancelButton.Text = 'Cancel'
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.CancelButton = $cancelButton
$form.Controls.Add($cancelButton)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(280,20)
$label.Text = "Please enter a group name:"
$form.Controls.Add($label)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10,40)
$textBox.Size = New-Object System.Drawing.Size(260,20)
$form.Controls.Add($textBox)

$label2 = New-Object System.Windows.Forms.Label
$label2.Location = New-Object System.Drawing.Point(10,70)
$label2.Size = New-Object System.Drawing.Size(280,20)
$label2.Text = "Please enter the display name you would like:"
$form.Controls.Add($label2)

$textBox2 = New-Object System.Windows.Forms.TextBox
$textBox2.Location = New-Object System.Drawing.Point(10,90)
$textBox2.Size = New-Object System.Drawing.Size(260,20)
$form.Controls.Add($textBox2)

$form.Topmost = $true

$form.Add_Shown({$textBox.Select()})
$form.Add_Shown({$textBox2.Select()})
$result = $form.ShowDialog()


if ($result -eq [System.Windows.Forms.DialogResult]::cancel)
{
     [void][System.Windows.Forms.MessageBox]::Show("New group creation cancelled!")
     exit
}


if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
   $Name = $textBox.Text
   $Name
   $Name1 = $textBox2.Text
   $Name1
 
}

 if ($RadioButton1.Checked){


$DLPath = "OU=DL,OU=Alex,DC=alex,DC=local"
New-DistributionGroup -Name $Name -DisplayName $Name1  -PrimarySmtpAddress $Name@alex.com  -OrganizationalUnit $DLPath -SamAccountName $Name
}

        elseif ($RadioButton2.Checked){
$Securitypath = "OU=Groups,OU=Alex,DC=alex,DC=local"
New-DistributionGroup -Name $Name -DisplayName $Name1   -PrimarySmtpAddress $Name@alex.com -Type Security -OrganizationalUnit $Securitypath  -SamAccountName $Name
}
       
    }
}
 
# Call the function
Groups_Form

