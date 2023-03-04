#$EXsession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://ex2019.alex.local/powershell
#Import-PSSession -session $Exsession -AllowClobber


Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Last Email Details"
$Form.Size = New-Object System.Drawing.Size(270,150)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog

$Label = New-Object System.Windows.Forms.Label
$Label.Location = New-Object System.Drawing.Point(10,20)
$Label.Size = New-Object System.Drawing.Size(280,20)
$Label.Text = "Enter distribution group email address:"
$Form.Controls.Add($Label)

$TextBox = New-Object System.Windows.Forms.TextBox
$TextBox.Location = New-Object System.Drawing.Point(10,40)
$Form.Controls.Add($TextBox)

$SearchButton = New-Object System.Windows.Forms.Button
$SearchButton.Location = New-Object System.Drawing.Point(10,70)
$SearchButton.Size = New-Object System.Drawing.Size(80,20)
$SearchButton.Text = "Search"
$SearchButton.Add_Click({
    $distributionGroup = $TextBox.Text

    if ([string]::IsNullOrWhiteSpace($distributionGroup)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a distribution group email address.", "Error")
        return
    }

    # Check if the distribution group exists
    $group = Get-DistributionGroup -Identity $distributionGroup -ErrorAction SilentlyContinue

    if (!$group) {
        [System.Windows.Forms.MessageBox]::Show("The distribution group $distributionGroup was not found.", "Email Search Results")
        return
    }

    try {
        $lastEmail = Get-MessageTrackingLog -Recipients $distributionGroup -ResultSize 100 -Start (Get-Date).AddDays(-30) |
        Sort-Object -Property Timestamp -Descending |
        Select-Object -First 1 |
        Select-Object Sender, MessageSubject, Timestamp

    } catch {
        Write-Host "Error getting message tracking log: $_"
        exit 1
    }

    if ($lastEmail) {
        $emailDetails = $lastEmail | Select-Object Sender, MessageSubject, @{ Name = "SentTime"; Expression = { $_.Timestamp.ToLocalTime() } }
        $emailDetails | Out-GridView
    } else {
        [System.Windows.Forms.MessageBox]::Show("No emails were sent to $distributionGroup in the last 30 days.", "Email Search Results")
    }

    $TextBox.Text = ""
})
$Form.Controls.Add($SearchButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Point(100,70)
$CancelButton.Size = New-Object System.Drawing.Size(80,20)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({ $Form.Close() })
$Form.Controls.Add($CancelButton)

$Form.ShowDialog() | Out-Null
