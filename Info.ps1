Param(

    [Parameter(Mandatory=$true)]

    [String]

    $Computername

)

 

 

$Credentials = Get-Credential $vinokura

 

#OS Description

$OS = (Get-WmiObject -class Win32_OperatingSystem -ComputerName $Computername -Credential $Credentials)

$cap = $OS.caption

$arch = $OS.OSArchitecture

 

#Disk Freespace on OS Drive

$drive = Get-WmiObject -class Win32_logicaldisk -ComputerName $Computername -Credential $Credentials | Where-Object DeviceID -eq "C:"

$freeSpace = [math]::Round(($drive.FreeSpace/1gb))

$totalDrive = [math]::Round(($drive.Size/1gb))

 

 

#Amount of System Memory

$memoryInGB = ((((Get-WmiObject -Class Win32_PhysicalMemory -ComputerName $Computername -Credential $Credentials ).capacity|measure -Sum).Sum)/1gb)

 

 

#Last Reboot of System

$lastReboot = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computername -Credential $Credentials  | Select-Object -Property @{n=”Last Boot Time”;e={[Management.ManagementDateTimeConverter]::ToDateTime($_.LastBootUpTime)}} | fl

 

 

#IP Address & DNS Name

$DNS = Resolve-DnsName -Name $Computername | Where-Object Type -eq "A" | Select-Object Name, IPAddress | fl

 

#DNS Server of Target

$adapters = Get-NetAdapter | Where-Object {$_.Name -eq "Ethernet"} | Select-Object Name



 

 

#Write Output to Screen

Write-Output "#######################################"

Write-Output "Windows version:"

Write-Output "$cap - $arch"

Write-Output "#######################################"

Write-output "$freeSpace GB out of $totalDrive GB"

Write-Output "#######################################"

Write-Output "Amount of System Memory:"

Write-Output "$memoryInGB GB"

Write-Output "#######################################"

Write-Output "Last Reboot of System:"

$lastReboot

Write-Output "#######################################"

Write-Output "IP Address & DNS Name:"

Write-Output $DNS

Write-Output "#######################################"

$serverAddress