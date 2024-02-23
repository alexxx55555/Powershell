Add-Type -AssemblyName System.Windows.Forms

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Delete AD User"
$form.Size = New-Object System.Drawing.Size(400, 150)
$form.StartPosition = "CenterScreen"

# Create input label
$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Location = New-Object System.Drawing.Point(10, 20)
$inputLabel.Size = New-Object System.Drawing.Size(150, 20)
$inputLabel.Text = "Enter user to delete:"
$form.Controls.Add($inputLabel)

# Create input textbox
$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(160, 20)
$inputBox.Size = New-Object System.Drawing.Size(150, 20)
$form.Controls.Add($inputBox)

# Create delete button
$deleteButton = New-Object System.Windows.Forms.Button
$deleteButton.Location = New-Object System.Drawing.Point(140, 60)
$deleteButton.Size = New-Object System.Drawing.Size(80, 30)
$deleteButton.Text = "Delete User"
$deleteButton.Add_Click({
    $Name = $inputBox.Text

    if ($Name) {
        # Check if the user exists by username or display name
        $user = Get-ADUser -Filter {(SamAccountName -eq $Name) -or (Name -eq $Name)} -ErrorAction SilentlyContinue

        if ($user) {
            # Prompt the user for confirmation before deleting
            $confirmation = [System.Windows.Forms.MessageBox]::Show("Are you sure you want to delete user $($user.Name)?", "Confirm", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question)

            if ($confirmation -eq "Yes") {
                # Delete the user from Active Directory
                Remove-ADUser -Identity $user.SamAccountName -Confirm:$false
                [System.Windows.Forms.MessageBox]::Show("User $($user.Name) has been deleted.", "Deleted", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
        } else {
            [System.Windows.Forms.MessageBox]::Show("User not found. Please check the username or display name.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please enter a username or display name.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})
$form.Controls.Add($deleteButton)

# Create cancel button
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(230, 60)
$cancelButton.Size = New-Object System.Drawing.Size(80, 30)
$cancelButton.Text = "Cancel"
$cancelButton.Add_Click({ $form.Close() })
$form.Controls.Add($cancelButton)

# Show the form
[void][System.Windows.Forms.Application]::EnableVisualStyles()
[void][System.Windows.Forms.Application]::Run($form)
