# Get the current execution policy
$currentPolicy = Get-ExecutionPolicy

# Set the execution policy to bypass for the entire system, if it's not already set to Bypass
if ($currentPolicy -ne 'Bypass') {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope LocalMachine -Force
}

# Ensure TLS 1.2 is enabled for secure web requests
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072

# Define the URL for the Chocolatey installation script
$chocoInstallUrl = 'https://chocolatey.org/install.ps1'

# Check if Chocolatey is already installed
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    try {
        # Download and execute the installation script
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($chocoInstallUrl))
        Write-Host "Chocolatey installed successfully."
    } catch {
        Write-Error "Failed to install Chocolatey. Error: $_"
    }
} else {
    Write-Host "Chocolatey is already installed."
}

# Ensure the 'allowGlobalConfirmation' feature is enabled in Chocolatey
try {
    $featureStatus = choco feature list | Select-String "allowGlobalConfirmation - Enabled"
    if (-not $featureStatus) {
        choco feature enable -n allowGlobalConfirmation
        Write-Host "'allowGlobalConfirmation' feature enabled in Chocolatey."
    } else {
        Write-Host "'allowGlobalConfirmation' feature is already enabled in Chocolatey."
    }
} catch {
    Write-Error "Failed to enable 'allowGlobalConfirmation' feature in Chocolatey. Error: $_"
}