# Load the necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Import-Module ActiveDirectory

# Create a new Windows Forms application
$Form = New-Object Windows.Forms.Form
$Form.Text = "Active Directory User Adder"
$Form.Size = New-Object Drawing.Size(450, 250)
$Form.StartPosition = 'CenterScreen'

# UI Elements Creation and Configuration
$LabelGroupName = New-Object Windows.Forms.Label
$LabelGroupName.Text = "Group Name:"
$LabelGroupName.Location = New-Object Drawing.Point(20, 20)
$LabelGroupName.AutoSize = $true

$TextBoxGroupName = New-Object Windows.Forms.TextBox
$TextBoxGroupName.Location = New-Object Drawing.Point(150, 20)
$TextBoxGroupName.Size = New-Object Drawing.Size(250, 20)

$LabelUsername = New-Object Windows.Forms.Label
$LabelUsername.Text = "Username:"
$LabelUsername.Location = New-Object Drawing.Point(20, 60)
$LabelUsername.AutoSize = $true

$TextBoxUsername = New-Object Windows.Forms.TextBox
$TextBoxUsername.Location = New-Object Drawing.Point(150, 60)
$TextBoxUsername.Size = New-Object Drawing.Size(250, 20)

$ButtonAddUser = New-Object Windows.Forms.Button
$ButtonAddUser.Text = "Add User"
$ButtonAddUser.Location = New-Object Drawing.Point(150, 100)
$ButtonAddUser.Size = New-Object Drawing.Size(100, 30)

$ButtonCancel = New-Object Windows.Forms.Button
$ButtonCancel.Text = "Cancel"
$ButtonCancel.Location = New-Object Drawing.Point(300, 100)
$ButtonCancel.Size = New-Object Drawing.Size(100, 30)

$StatusLabel = New-Object Windows.Forms.Label
$StatusLabel.Location = New-Object Drawing.Point(20, 150)
$StatusLabel.Size = New-Object Drawing.Size(400, 20)
$StatusLabel.ForeColor = [System.Drawing.Color]::Red

# Add controls to the form
$Form.Controls.AddRange(@($LabelGroupName, $TextBoxGroupName, $LabelUsername, $TextBoxUsername, $ButtonAddUser, $ButtonCancel, $StatusLabel))

# Function to check if the group exists
function Group-Exists {
    param (
        [string]$GroupName
    )
    return Get-ADGroup -Filter { Name -eq $GroupName } -ErrorAction SilentlyContinue
}

# Function to check if the user exists
function User-Exists {
    param (
        [string]$Username
    )
    return Get-ADUser -Filter { SamAccountName -eq $Username } -ErrorAction SilentlyContinue
}
# Validate Inputs
function Validate-Input {
    param (
        [string]$GroupName,
        [string]$Username
    )
    if (-not $GroupName -or -not $Username) {
        throw "Both Group Name and Username are required."
    }

    if (-not (Group-Exists -GroupName $GroupName)) {
        throw "Group '$GroupName' does not exist."
    }

    if (-not (User-Exists -Username $Username)) {
        throw "User '$Username' does not exist."
    }
}

# Function to add user to group
function Add-UserToGroup {
    param (
        [string]$GroupName,
        [string]$Username
    )

    try {
           Validate-Input -GroupName $GroupName -Username $Username
                   # Asynchronous operation to add user to group
        Start-Job -ScriptBlock {
            Add-ADGroupMember -Identity $Using:GroupName -Members $Using:Username
        } | Wait-Job

        return $true
    } catch {
        return $_.Exception.Message
    }
}

# Button Click Events
$ButtonAddUser.Add_Click({
    $result = Add-UserToGroup -GroupName $TextBoxGroupName.Text -Username $TextBoxUsername.Text
    if ($result -eq $true) {
        $StatusLabel.Text = "User '$($TextBoxUsername.Text)' successfully added to group '$($TextBoxGroupName.Text)'"
        $StatusLabel.ForeColor = [System.Drawing.Color]::Green
    } else {
        $StatusLabel.Text = "Error: $result"
        $StatusLabel.ForeColor = [System.Drawing.Color]::Red
    }
})

$ButtonCancel.Add_Click({
    $Form.Close()
})

# Show the form
$Form.ShowDialog()

# Dispose of the form when done
$Form.Dispose()

