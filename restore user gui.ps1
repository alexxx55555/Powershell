###### Make sure the AD recyclebin is enabled ######

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form and controls
$Form = New-Object System.Windows.Forms.Form
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$Label = New-Object System.Windows.Forms.Label
$TextBox = New-Object System.Windows.Forms.TextBox
$Button = New-Object System.Windows.Forms.Button
$CancelButton = New-Object System.Windows.Forms.Button

# Configure the form and controls
$Form.Text = "Restore Deleted Users"
$Form.StartPosition = "CenterScreen"
$Form.ClientSize = New-Object System.Drawing.Size(280, 120)

$Label.Text = "Enter the name of the deleted user:"
$Label.AutoSize = $true
$Label.Location = New-Object System.Drawing.Point(10, 20)

$TextBox.Location = New-Object System.Drawing.Point(10, 50)
$TextBox.Size = New-Object System.Drawing.Size(185, 20)

$Button.Text = "Restore"
$Button.Location = New-Object System.Drawing.Point(10, 80)

$CancelButton.Text = "Cancel"
$CancelButton.Location = New-Object System.Drawing.Point(120, 80)


# Add event handler for the button click
$Button.Add_Click({
    $Name = $TextBox.Text.Trim()
    
    if (!$Name) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a valid user name.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }
    
    if ($Name -eq 'done') {
        $Form.Close()
        return
    }
    
    $User = Get-ADObject -Filter { SamAccountName -eq $Name } -IncludeDeletedObjects -Properties * -ErrorAction Stop
    
    if (!$User) {
        [System.Windows.Forms.MessageBox]::Show("User $Name not found.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    elseif ($User.isDeleted -eq $false) {
        [System.Windows.Forms.MessageBox]::Show("User $Name has not been deleted.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
    else {
        try {
            Restore-ADObject -Identity $User.ObjectGUID -ErrorAction Stop
            [System.Windows.Forms.MessageBox]::Show("User $Name has been restored.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

            # Logging
            $Log = "User '$Name' restored by '$env:USERNAME' at $(Get-Date)"
            Add-Content -Path "C:\ADRestore.log" -Value $Log
        }
        catch {
            [System.Windows.Forms.MessageBox]::Show("User $Name has not been deleted.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    }
    
    $TextBox.Text = ""
})

# Add event handler for the cancel button click
$CancelButton.Add_Click({
    $Form.Close()
})

# Add the controls to the form
$Form.Controls.Add($Label)
$Form.Controls.Add($TextBox)
$Form.Controls.Add($Button)
$Form.Controls.Add($CancelButton)

# Display the form
$Form.ShowDialog() | Out-Null
