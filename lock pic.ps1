$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
# CSP Registry key names
$LockScreenImagePath = "LockScreenImagePath"
$LockScreenImageStatus = "LockScreenImageStatus"
# CSP Status
$StatusValue = "1"
# Image to use
$LockScreenImageValue = "\\dc1\Applications\pic.jpg"  # Change as per your needs
## Check if PersonalizationCSP registry exist and if not create it and add values, or just create the values under it.
if(!(Test-Path $RegKeyPath)){
    New-Item -Path $RegKeyPath -Force | Out-Null
    # Allows for administrators to query the status of the lock screen image.
    New-ItemProperty -Path $RegKeyPath -Name $LockScreenImageStatus -Value $StatusValue -PropertyType DWORD -Force | Out-Null
    # Set the image to use as lock screen background.
    New-ItemProperty -Path $RegKeyPath -Name $LockScreenImagePath -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null
}
else {
    # Allows for administrators to query the status of the lock screen image.
    New-ItemProperty -Path $RegKeyPath -Name $LockScreenImageStatus -Value $value -PropertyType DWORD -Force | Out-Null
    # Set the image to use as lock screen background.
    New-ItemProperty -Path $RegKeyPath -Name $LockScreenImagePath -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null
}