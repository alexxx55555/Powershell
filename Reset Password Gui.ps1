Add-Type -AssemblyName System.Windows.Forms
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.VisualBasic")
function Reset-ADUserPassword {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$UserName,
        [Parameter(Mandatory)]
        [string]$NewPassword,
        [string]$DomainController = "DC1"
    )

    $Title = "Reset Password"
    $Default = $null

    if ([string]::IsNullOrWhiteSpace($UserName)) {
        Write-Error "Username cannot be empty."
        return
    }

    if ([string]::IsNullOrWhiteSpace($NewPassword)) {
        Write-Error "New password cannot be empty."
        return
    }

    $NewPasswordSecure = ConvertTo-SecureString -String $NewPassword -AsPlainText -Force

    $paramHash = @{
        Identity = $UserName
        NewPassword = $NewPasswordSecure
        Reset = $True
        PassThru = $True
        ErrorAction = "Stop"
    }

    try {
        $output = Set-ADAccountPassword -Server $DomainController @paramHash |
                  Get-ADUser -Properties PasswordLastSet,PasswordExpired,WhenChanged

        if ($output) {
            $message = "The password for user $UserName has been reset."
            $button = "OKOnly"
            $icon = "Information"
            [microsoft.visualbasic.interaction]::Msgbox($message, "$button,$icon", $Title) | Out-Null
        }
        else {
            $message = "User not found. Please enter a valid username."
            $button = "OKOnly"
            $icon = "Exclamation"
            [microsoft.visualbasic.interaction]::Msgbox($message, "$button,$icon", $Title) | Out-Null
        }
    }
    catch {
        $message = "Failed to reset password for $UserName. $($_.Exception.Message)"
        $button = "OKOnly"
        $icon = "Exclamation"
        [microsoft.visualbasic.interaction]::Msgbox($message, "$button,$icon", $Title) | Out-Null
    }
}
function Reset-ADUserPasswordGUI {
    [CmdletBinding()]
    param(
        [switch]$KeepOpen
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Reset AD User Password"
    $form.Width = 400
    $form.Height = 200
    $form.StartPosition = "CenterScreen"

    $labelUserName = New-Object System.Windows.Forms.Label
    $labelUserName.Location = New-Object System.Drawing.Point(20, 20)
    $labelUserName.Size = New-Object System.Drawing.Size(100, 23)
    $labelUserName.Text = "User Name:"
    $form.Controls.Add($labelUserName)

    $textBoxUserName = New-Object System.Windows.Forms.TextBox
    $textBoxUserName.Location = New-Object System.Drawing.Point(130, 20)
    $textBoxUserName.Size = New-Object System.Drawing.Size(200, 23)
    $form.Controls.Add($textBoxUserName)

    $labelNewPassword = New-Object System.Windows.Forms.Label
    $labelNewPassword.Location = New-Object System.Drawing.Point(20, 60)
    $labelNewPassword.Size = New-Object System.Drawing.Size(100, 23)
    $labelNewPassword.Text = "New Password:"
    $form.Controls.Add($labelNewPassword)

    $textBoxNewPassword = New-Object System.Windows.Forms.TextBox
    $textBoxNewPassword.Location = New-Object System.Drawing.Point(130, 60)
    $textBoxNewPassword.Size = New-Object System.Drawing.Size(200, 23)
    $textBoxNewPassword.PasswordChar = "*"
    $form.Controls.Add($textBoxNewPassword)

    $buttonResetPassword = New-Object System.Windows.Forms.Button
    $buttonResetPassword.Location = New-Object System.Drawing.Point(130, 100)
    $buttonResetPassword.Size = New-Object System.Drawing.Size(100, 23)
    $buttonResetPassword.Text = "Reset Password"
    $buttonResetPassword.DialogResult = [System.Windows.Forms.DialogResult]::None
    $form.AcceptButton = $buttonResetPassword
    $form.Controls.Add($buttonResetPassword)

    $buttonCancel = New-Object System.Windows.Forms.Button
    $buttonCancel.Location = New-Object System.Drawing.Point(240, 100)
    $buttonCancel.Size = New-Object System.Drawing.Size(100, 23)
    $buttonCancel.Text = "Cancel"
    $buttonCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.CancelButton = $buttonCancel
    $form.Controls.Add($buttonCancel)

    $form.Topmost = $true

$buttonResetPassword.Add_Click({
    $userName = $textBoxUserName.Text
    $newPassword = $textBoxNewPassword.Text

    if ([string]::IsNullOrWhiteSpace($userName)) {
        [System.Windows.Forms.MessageBox]::Show("Username cannot be empty.")
        return
    }

    if ([string]::IsNullOrWhiteSpace($newPassword)) {
        [System.Windows.Forms.MessageBox]::Show("New Password cannot be empty.")
        return
    }

    try {
        Reset-ADUserPassword -UserName $userName -NewPassword $newPassword
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show("Failed to reset password for $userName. $($_.Exception.Message)")
    }
})





    $result = $form.ShowDialog()

    $form.Dispose()
}





Reset-ADUserPasswordGUI
