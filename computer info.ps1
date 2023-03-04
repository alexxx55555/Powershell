Add-Type -AssemblyName System.Windows.Forms

# Create a form
$form = New-Object System.Windows.Forms.Form
$form.Text = "System Information"
$form.Size = New-Object System.Drawing.Size(300, 120)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false  # Disable maximize button


# Create labels and textboxes for user input
$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10, 10)
$label.Size = New-Object System.Drawing.Size(80, 20)
$label.Text = "Select option:"
$label.AutoSize = $false
$form.Controls.Add($label)

$dropdown = New-Object System.Windows.Forms.ComboBox
$dropdown.Location = New-Object System.Drawing.Point(100, 10)
$dropdown.Size = New-Object System.Drawing.Size(150, 20)
$dropdown.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$dropdown.Items.AddRange(("OS Version", "Last Windows Update", "Hostname", "IP Address", "Serial Number", "MAC Address", "System Uptime", "Disk Space", "Installed Software"))
$dropdown.Margin = New-Object System.Windows.Forms.Padding(2, 0, 0, 0)  # Set the margin
$form.Controls.Add($dropdown)

# Add buttons to the form
$button1 = New-Object System.Windows.Forms.Button
$button1.Location = New-Object System.Drawing.Point(10, 50)
$button1.Size = New-Object System.Drawing.Size(110, 30)
$button1.Text = "Get Info"
$form.Controls.Add($button1)

$button2 = New-Object System.Windows.Forms.Button
$button2.Location = New-Object System.Drawing.Point(170, 50)
$button2.Size = New-Object System.Drawing.Size(110, 30)
$button2.Text = "Exit"
$form.Controls.Add($button2)

# Add event handlers for the buttons
$button1.Add_Click({
    if ($dropdown.SelectedItem -eq $null) {
        [System.Windows.Forms.MessageBox]::Show("Please select an option.")
        return
    }
    
   $option = $dropdown.SelectedItem.ToString()
    switch ($option) {
        "OS Version" {
            $os = Get-WmiObject Win32_OperatingSystem
            $osName = $os.Caption
            $osVersion = $os.Version
            [System.Windows.Forms.MessageBox]::Show("Your Operation system is: $osName, version $osVersion")
        }
       
        "Last Windows Update" {
    $lastUpdate = (Get-Hotfix | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn
    $formattedDate = $lastUpdate.ToString("dd-MM-yyyy")
    [System.Windows.Forms.MessageBox]::Show("Your last Windows update was installed on: $formattedDate")
}
     
       
        "Hostname" {

            $hostname = (Get-WmiObject Win32_ComputerSystem).Name
            [System.Windows.Forms.MessageBox]::Show("Your hostname is: $hostname")
        }
     
"IP Address" {
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Select IP Address"
    $form.ClientSize = New-Object System.Drawing.Size(300, 100)
    $form.StartPosition = "CenterScreen"
    $form.Topmost = $true
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false  # Disable maximize button
    $form.MinimizeBox = $false  # Disable minimize button

    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Please select your network interface:"
    $label.Location = New-Object System.Drawing.Point(50, 10)
    $label.AutoSize = $true
    $form.Controls.Add($label)

    $wifiButton = New-Object System.Windows.Forms.Button
    $wifiButton.Text = "Wi-Fi"
    $wifiButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $wifiButton.Top = 30
    $wifiButton.Left = 50
    $form.Controls.Add($wifiButton)

    $lanButton = New-Object System.Windows.Forms.Button
    $lanButton.Text = "LAN"
    $lanButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
    $lanButton.Top = 30
    $lanButton.Left = 150
    $form.Controls.Add($lanButton)

    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $adapter = Get-NetAdapter | Where-Object { $_.Name -like "Wi-Fi*" }
        if (!$adapter) {
            [System.Windows.Forms.MessageBox]::Show("Wi-Fi interface is not connected to the network.")
            return
        }
        $ipv4 = $adapter | Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' -or $_.PrefixOrigin -eq 'Manual' }
        if (!$ipv4) {
            [System.Windows.Forms.MessageBox]::Show("Wi-Fi interface does not have an IP address.")
            return
        }
        $ip = $ipv4.IPAddress
        [System.Windows.Forms.MessageBox]::Show("Your Wi-Fi IP address is: $ip")
    } elseif ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $adapter = Get-NetAdapter | Where-Object { $_.Name -like "Ethernet*" }
        if (!$adapter) {
            [System.Windows.Forms.MessageBox]::Show("LAN interface is not connected to the network.")
            return
        }
        $ipv4 = $adapter | Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' -or $_.PrefixOrigin -eq 'Manual' }
        if (!$ipv4) {
            [System.Windows.Forms.MessageBox]::Show("LAN interface does not have an IP address.")
            return
        }
        $ip = $ipv4.IPAddress
        [System.Windows.Forms.MessageBox]::Show("Your LAN IP address is: $ip")
    } else {
        $form.Close()
    }
}




        
        "MAC Address" {
            $form = New-Object System.Windows.Forms.Form
            $form.Text = "Select MAC Address"
            $form.ClientSize = New-Object System.Drawing.Size(300, 100)
            $form.StartPosition = "CenterScreen"
            $form.Topmost = $true
            $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
            $form.MaximizeBox = $false  # Disable maximize button
            
        
            $label = New-Object System.Windows.Forms.Label
            $label.Text = "Please select your network interface:"
            $label.Location = New-Object System.Drawing.Point(50, 10)
            $label.AutoSize = $true
            $form.Controls.Add($label)
        
            $wifiButton = New-Object System.Windows.Forms.Button
            $wifiButton.Text = "Wi-Fi"
            $wifiButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
            $wifiButton.Top = 30
            $wifiButton.Left = 50
            $form.Controls.Add($wifiButton)
        
            $lanButton = New-Object System.Windows.Forms.Button
            $lanButton.Text = "LAN"
            $lanButton.DialogResult = [System.Windows.Forms.DialogResult]::Yes
            $lanButton.Top = 30
            $lanButton.Left = 150
            $form.Controls.Add($lanButton)

            $result = $form.ShowDialog()
            
          if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $mac = (Get-NetAdapter | Where-Object { $_.Name -like "Wi-Fi*" }).MacAddress
        [System.Windows.Forms.MessageBox]::Show("Your Wi-Fi MAC address is: $mac")
    } elseif ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $mac = (Get-NetAdapter | Where-Object { $_.Name -like "Ethernet*" }).MacAddress 
        [System.Windows.Forms.MessageBox]::Show("Your LAN MAC address is: $mac")
    } else {
    $form.Close()
            }
        }        
"System Uptime" {
    $bootTime = (Get-WmiObject Win32_OperatingSystem).LastBootUpTime
    $bootTime = [System.Management.ManagementDateTimeConverter]::ToDateTime($bootTime)

    $now = Get-Date
    $uptime = $now - $bootTime

    $uptime = $uptime.Days.ToString() + " days, " + $uptime.Hours.ToString() + " hours, " + $uptime.Minutes.ToString() + " minutes, " + $uptime.Seconds.ToString() + " seconds"
    [System.Windows.Forms.MessageBox]::Show("Your system uptime is: $uptime")
}

"Serial Number" {
$serial = (Get-WmiObject -Class Win32_ComputerSystemProduct).IdentifyingNumber
[System.Windows.Forms.MessageBox]::Show("Your serial number is: $serial")
}

"Disk Space" {
$diskspace = Get-WmiObject Win32_LogicalDisk | Select-Object DeviceID, @{Name="Size (GB)";Expression={$_.Size/1GB -as [int]}}, @{Name="FreeSpace (GB)";Expression={$_.FreeSpace/1GB -as [int]}}
$message = "Your available disk space is:`r`n"
foreach ($disk in $diskspace) {
    $message += "Drive $($disk.DeviceID): $($disk.'FreeSpace (GB)') GB free out of $($disk.'Size (GB)') GB`r`n"
}
[System.Windows.Forms.MessageBox]::Show($message)
}

"Installed Software" {
  $installedSoftware = Get-WmiObject -Class Win32_Product | Select-Object Name, Version
$softwareList = "The installed software on your system is:`r`n`r`n"
foreach ($software in $installedSoftware) {
    $name = $software.Name
    $version = $software.Version
    $softwareList += "$name $version`r`n"
}
$messageBox = New-Object System.Windows.Forms.Form
$messageBox.Text = "Installed Software"
$messageBoxIcon = [System.Windows.Forms.MessageBoxIcon]::Information
try {
} catch {
$messageBox.Buttons = [System.Windows.Forms.MessageBoxButtons]::OKCancel

    Write-Error $_.Exception.Message
}
$messageBox.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$messageBox.MaximizeBox = $false
$messageBox.MinimizeBox = $false
$messageBox.ClientSize = New-Object System.Drawing.Size(400, 300)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(10, 10)
$textBox.Size = New-Object System.Drawing.Size(380, 200)
$textBox.Multiline = $true
$textBox.ScrollBars = [System.Windows.Forms.ScrollBars]::Both
$textBox.Text = $softwareList
$messageBox.Controls.Add($textBox)




$exportButton = New-Object System.Windows.Forms.Button
$exportButton.Location = New-Object System.Drawing.Point(115, 230)
$exportButton.Size = New-Object System.Drawing.Size(80, 30)
$exportButton.Text = "Export"
$exportButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$exportButton.Add_Click({
    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Filter = "CSV file (*.csv)|*.csv"
    $saveFileDialog.Title = "Export Installed Software"
    if ($saveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $installedSoftware | Export-Csv -Path $saveFileDialog.FileName -NoTypeInformation
    }
})
$messageBox.Controls.Add($exportButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Location = New-Object System.Drawing.Point(215, 230)
$cancelButton.Size = New-Object System.Drawing.Size(80, 30)
$cancelButton.Text = "Cancel"
$cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$cancelButton.Add_Click({
    $messageBox.Close()
})
$messageBox.Controls.Add($cancelButton)

$result = $messageBox.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
    # Do something if OK button is clicked
}

}

}
})

$button2.Add_Click({ $form.Close() })
$form.Add_Shown({ $dropdown.Select() })
[void] $form.ShowDialog()