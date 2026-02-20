#Requires -RunAsAdministrator
# ============================================================
# Run this ONCE on each Domain Controller to register the task
# ============================================================

# 1. Register the event source (for logging)
try {
    New-EventLog -LogName Application -Source "ADGroupMonitor" -ErrorAction Stop
} catch {
    Write-Host "Event source already exists, skipping..." -ForegroundColor Yellow
}

# 2. Set the path to the monitor script
$ScriptPath = "C:\Scripts\Monitor-GroupMembership.ps1"

# 3. Create the folder
if (-not (Test-Path "C:\Scripts")) {
    New-Item -Path "C:\Scripts" -ItemType Directory | Out-Null
}

$TaskName = "AD Group Membership Monitor"

# Remove existing task if present
schtasks /Delete /TN "$TaskName" /F 2>$null

# Register with proper event triggers via XML
$TaskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <Triggers>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>&lt;QueryList&gt;&lt;Query Id="0" Path="Security"&gt;&lt;Select Path="Security"&gt;*[System[(EventID=4728 or EventID=4729 or EventID=4732 or EventID=4733 or EventID=4756 or EventID=4757)]]&lt;/Select&gt;&lt;/Query&gt;&lt;/QueryList&gt;</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-18</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>Queue</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
  </Settings>
  <Actions>
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -NoProfile -File "$ScriptPath"</Arguments>
    </Exec>
  </Actions>
</Task>
"@

Register-ScheduledTask -TaskName $TaskName -Xml $TaskXml -Force | Out-Null

# Verify it was created
$Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($Task) {
    Write-Host ""
    Write-Host "Task registered successfully!" -ForegroundColor Green
    Write-Host "  Status: $($Task.State)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "  1. Ensure monitor script is at: $ScriptPath"
    Write-Host "  2. Test: net localgroup `"Some Group`" someuser /add"
    Write-Host "  3. Check Task Scheduler and #security-alerts in Slack"
} else {
    Write-Host ""
    Write-Host "ERROR: Task was not created. Check the error above." -ForegroundColor Red
}