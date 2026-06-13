# AD User Editor — Web App

A browser-based replacement for the WinForms AD user editor.
Built with **Pode** (PowerShell web framework) + plain HTML/JS.

## Requirements

- Windows machine joined to `alex.local`
- RSAT (ActiveDirectory module) installed
- PowerShell 5.1 or 7+
- Pode module

## Quick start

### 1. Install Pode (once)
```powershell
Install-Module -Name Pode -Scope CurrentUser
```

### 2. Run the server
```powershell
cd "C:\path\to\ad-web-editor"
.\Start-ADWebEditor.ps1
```

Open **http://localhost:8080** in your browser.
Press `Ctrl+C` in the terminal to stop.

---

## Expose via Nginx Proxy Manager (recommended)

So you can reach it at `ad.alex-it.net` from inside your network:

1. In NPM, add a new **Proxy Host**:
   - Domain: `ad.alex-it.net`
   - Forward Hostname: IP of your Windows machine (e.g. `192.168.1.10`)
   - Forward Port: `8080`
   - Enable SSL with your Cloudflare cert

2. In Windows Firewall, allow inbound TCP 8080:
```powershell
New-NetFirewallRule -DisplayName "Pode AD Editor" -Direction Inbound `
    -Protocol TCP -LocalPort 8080 -Action Allow
```

---

## Run as a Windows Service (optional)

So it starts automatically without being logged in:

```powershell
# Install NSSM (Non-Sucking Service Manager)
winget install NSSM.NSSM

# Create the service
nssm install ADUserEditor powershell.exe
nssm set ADUserEditor AppParameters "-NoProfile -ExecutionPolicy Bypass -File C:\path\to\ad-web-editor\Start-ADWebEditor.ps1"
nssm set ADUserEditor AppDirectory "C:\path\to\ad-web-editor"
nssm set ADUserEditor ObjectName "DOMAIN\ServiceAccount"  # needs AD write perms
nssm start ADUserEditor
```

---

## Configuration

Edit the `$Config` block at the top of `Start-ADWebEditor.ps1`:

```powershell
$Config = @{
    SearchBase     = "OU=Users,OU=Alex,DC=alex,DC=local"
    MaxResults     = 1000
    Port           = 8080
    UseHttps       = $false       # set $true + provide thumbprint for direct HTTPS
    CertThumbprint = ""
}
```

---

## File structure

```
ad-web-editor/
├── Start-ADWebEditor.ps1   ← Pode server + all AD logic
└── public/
    └── index.html          ← Full frontend (single file, no build step)
```
