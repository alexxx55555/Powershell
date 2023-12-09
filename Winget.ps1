# Check if Winget is installed
$wingetPath = Get-Command winget -ErrorAction SilentlyContinue
if (-not $wingetPath) {
    Write-Host "Winget is not installed on this computer. Please install Winget and try again." -ForegroundColor Red
    exit
}

Function Start-NewSearch {
    # Prompt the user for the app they want to install
    $appName = Read-Host "Enter the name of the app you want to install (or type 'done' to exit)"

    # Check if the user wants to exit
    if ($appName -eq 'done') {
        exit
    }

    Search-And-Install $appName
}

Function Search-And-Install ($appName) {
    # Search for the app using Winget
    $searchResults = winget search $appName | Select-Object -Skip 3 | Out-String -Stream

    # Filter out empty lines and lines that don't start with a name and version
    $packages = $searchResults | Where-Object { $_ -match '^\S+\s+\S+' } | ForEach-Object { $_.Trim() }

    # Check the number of matching packages
    $packageCount = $packages.Count

    if ($packageCount -eq 0) {
        Write-Host "No packages found matching '$appName'." -ForegroundColor Red
        Start-NewSearch
    }
    elseif ($packageCount -eq 1) {
        # Only one matching package, install it
        $packageToInstall = ($packages -split '\s+')[0]
        Write-Host "Installing $packageToInstall..." -ForegroundColor Green
        winget install $packageToInstall
        Start-NewSearch
    }
    else {
        # Multiple matching packages, ask the user to choose one
        Write-Host "Multiple packages found matching '$appName'. Please choose one:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $packageCount; $i++) {
            Write-Host "[$i] $($packages[$i])"
        }
        Write-Host "[$packageCount] Start a new search"
        $choice = Read-Host "Enter the number of the package you want to install, or $packageCount to start a new search"
        if (-not $choice -match '^\d+$' -or [int]$choice -lt 0 -or [int]$choice -gt $packageCount) {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
            Search-And-Install $appName
        }
        elseif ([int]$choice -eq $packageCount) {
            Start-NewSearch
        }
        else {
            $packageToInstall = ($packages[[int]$choice] -split '\s+')[0]
            Write-Host "Installing $packageToInstall..." -ForegroundColor Green
            winget install $packageToInstall
            Start-NewSearch
        }
    }
}

# Start the first searchaa
Start-NewSearch
