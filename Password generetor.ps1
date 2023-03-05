Add-Type -AssemblyName System.Windows.Forms

function Generate-RandomPassword {
    param(
        [int]$length = 8,
        [string]$allowedChars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{};:,.<>?'
    )

    if ($length -lt 8 -or $length -gt 10) {
        throw "Invalid password length. Must be between 8 and 10 characters."
    }

    $rng = New-Object System.Security.Cryptography.RNGCryptoServiceProvider
    $bytes = New-Object byte[] $length
    $rng.GetBytes($bytes)

    $password = ""
    for ($i = 0; $i -lt $length; $i++) {
        $charIndex = $bytes[$i] % $allowedChars.Length
        $password += $allowedChars[$charIndex]
    }

    return $password
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Password Generator"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Fixed3D
$form.MaximizeBox = $true
$form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$form.Width = 300
$form.Height = 120

$label = New-Object System.Windows.Forms.Label
$label.Text = "Password:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(10, 20)
$form.Controls.Add($label)

$passwordField = New-Object System.Windows.Forms.TextBox
$passwordField.ReadOnly = $true
$passwordField.BackColor = [System.Drawing.Color]::LightGray
$passwordField.Location = New-Object System.Drawing.Point(70, 20)
$passwordField.Width = 200
$passwordField.ShortcutsEnabled = $false
$form.Controls.Add($passwordField)

$generateButton = New-Object System.Windows.Forms.Button
$generateButton.Text = "Generate Password"
$generateButton.Location = New-Object System.Drawing.Point(10, 60)
$generateButton.Width = 120
$generateButton.add_Click({
    $password = Generate-RandomPassword
    $passwordField.Text = $password
})
$form.Controls.Add($generateButton)

$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Text = "Copy"
$copyButton.Location = New-Object System.Drawing.Point(140, 60)
$copyButton.Width = 60
$copyButton.add_Click({
    [System.Windows.Forms.Clipboard]::SetText($passwordField.Text)
})
$form.Controls.Add($copyButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = "Cancel"
$cancelButton.Location = New-Object System.Drawing.Point(210, 60)
$cancelButton.Width = 60
$cancelButton.add_Click({
    $form.Close()
})
$form.Controls.Add($cancelButton)

$form.AcceptButton = $generateButton
$form.CancelButton = $cancelButton

$form.ShowDialog() | Out-Null
