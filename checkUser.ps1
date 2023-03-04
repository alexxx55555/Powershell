function userCovert($username){
    if($userName.split('',[System.StringSplitOptions]::RemoveEmptyEntries).Length -gt 1){
        return "DisplayName -eq '$username'"
    } else{
        return "SamAccountName -eq '$username'"
    }
}

$userName = Read-Host "Username"
$userName = $userName.Trim()
$statement = userCovert($username)


while($userName){
    get-aduser -filter $statement -Properties PasswordExpired, CN, DisplayName, CanonicalName, LockedOut, msRTCSIP-PrimaryUserAddress, memberof, msExchArchiveStatus | select @{Name="Username"; Expression={$_.SamAccountName}}, @{Name="Display Name <> CN"; Expression={if($_.DisplayName -eq $_.CN){$compareDisplayCN = "Same"}else{$compareDisplayCN = "Different"};($_.DisplayName,$_.CN) -join " < $compareDisplayCN > "}}, @{Name="OU"; Expression={((($_).CanonicalName).replace("/","\")).replace("corp.amdocs.com\","")}}, @{Name="SIP (Skype) Address"; Expression={$_."msRTCSIP-PrimaryUserAddress".split(":")[1]}}, @{Name="On-Cloud"; Expression={$onCloud = ($_).msExchArchiveStatus; if($onCloud -gt 0){$true}else{$false}}}, @{Name="IsPasswordExpired"; Expression={$_.PasswordExpired}}, @{Name="IsUserLocked"; Expression={$_.LockedOut}}, Enabled, @{Name="Groups"; Expression={($_).memberof | foreach -Begin{$listGroups = @()} -process{
        $groupName = $_.split(",")[0].split("=")[1]

        # Add custom keywords to search the user's groups.
        $groups = "USB", "eTips", "Teams", "ATTO2A", "PST"
        foreach($group in $groups){
            if($groupName -like "*$group*"){
              $listGroups+= "$group Group: " + $groupName + "`n"
              }
           }
        } -end{$sortedGroups = ($listGroups | sort); $sortedGroups -join ""}
    }
    }
    $userName = Read-Host "Username"
    $userName = $userName.Trim()
    $statement = userCovert($username)
}
