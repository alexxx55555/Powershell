Import-Module Pode
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

function New-TOTPBase32Secret {
    $bytes = New-Object byte[] 20
    [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    $result = ""; $buffer = 0; $bitsLeft = 0
    foreach ($b in $bytes) {
        $buffer = ($buffer -shl 8) -bor $b; $bitsLeft += 8
        while ($bitsLeft -ge 5) { $bitsLeft -= 5; $result += $chars[($buffer -shr $bitsLeft) -band 31] }
    }
    return $result
}
function Get-Base32Bytes { param([string]$Secret)
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"; $bits = ""
    foreach ($c in $Secret.ToUpper().ToCharArray()) { $bits += [Convert]::ToString($chars.IndexOf($c),2).PadLeft(5,"0") }
    $bytes = @()
    for ($i=0; $i+8 -le $bits.Length; $i+=8) { $bytes += [Convert]::ToByte($bits.Substring($i,8),2) }
    return [byte[]]$bytes
}
function Test-TOTPCode { param([string]$Base32Secret,[string]$Code)
    foreach ($drift in @(-1,0,1)) {
        $key = Get-Base32Bytes -Secret $Base32Secret
        $time = [long]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds()/30)+$drift
        $tb = [BitConverter]::GetBytes($time)
        if ([BitConverter]::IsLittleEndian) { [Array]::Reverse($tb) }
        $hmac = New-Object System.Security.Cryptography.HMACSHA1; $hmac.Key=$key
        $hash = $hmac.ComputeHash($tb); $off = $hash[19] -band 15
        $val = ((($hash[$off] -band 127) -shl 24) -bor (($hash[$off+1] -band 255) -shl 16) -bor (($hash[$off+2] -band 255) -shl 8) -bor ($hash[$off+3] -band 255)) % 1000000
        if ($val.ToString("000000") -eq $Code) { return $true }
    }
    return $false
}
function Get-TOTPSecrets {
    $path = "C:\ADUserEditor\totp-secrets.json"
    if (Test-Path $path) { return Get-Content $path -Raw | ConvertFrom-Json }
    return [PSCustomObject]@{}
}
function Save-TOTPSecret { param([string]$Username,[string]$Secret)
    $s = Get-TOTPSecrets
    $s | Add-Member -NotePropertyName $Username -NotePropertyValue $Secret -Force
    $s | ConvertTo-Json | Set-Content "C:\ADUserEditor\totp-secrets.json"
}
Start-PodeServer -Threads 2 {
    Add-PodeEndpoint -Address * -Port 8080 -Protocol Http
    Enable-PodeSessionMiddleware -Duration 3600
    Add-PodeMiddleware -Name "Auth" -ScriptBlock {
        $path = $WebEvent.Path
        $open = @("/login","/login/totp","/login/setup","/login/setup-data")
        if ($open -contains $path) { return $true }
        $ok = $WebEvent.Session.Data.LoggedIn -eq $true
        if (-not $ok -and $path -like "/api/*") { Write-PodeJsonResponse -Value @{ error = "Unauthorized. Please log in." }; return $false }
        if (-not $ok) { Move-PodeResponseUrl -Url "/login"; return $false }
        return $true
    }
    Add-PodeMiddleware -Name "CORS" -ScriptBlock {
        Set-PodeHeader -Name "Access-Control-Allow-Origin" -Value "*"
        Set-PodeHeader -Name "Access-Control-Allow-Methods" -Value "GET, POST, PUT, OPTIONS"
        Set-PodeHeader -Name "Access-Control-Allow-Headers" -Value "Content-Type"
        if ($WebEvent.Method -ieq "OPTIONS") { Set-PodeResponseStatus -Code 204; return $false }
        return $true
    }
    Add-PodeRoute -Method Get -Path "/login" -ScriptBlock {
        Write-PodeFileResponse -Path "C:\ADUserEditor\public\login.html" -ContentType "text/html"
    }
    Add-PodeRoute -Method Post -Path "/login" -ScriptBlock {
        $body = [string]$WebEvent.Request.Body | ConvertFrom-Json
        $un = [string]$body.username; $pw = [string]$body.password
        if ([string]::IsNullOrEmpty($un) -or [string]::IsNullOrEmpty($pw)) { Write-PodeJsonResponse -Value @{ error = "Username and password required." }; return }
        $auth = $false
        try {
            $entry = New-Object System.DirectoryServices.DirectoryEntry("LDAP://alex.local","alex.local\$un",$pw)
            $s = New-Object System.DirectoryServices.DirectorySearcher($entry)
            $s.Filter = "(&(objectClass=user)(sAMAccountName=$un))"
            if ($s.FindOne()) { $auth = $true }
        } catch { $auth = $false }
        if (-not $auth) { Write-PodeJsonResponse -Value @{ error = "Invalid username or password." }; return }
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        $adUser = Get-ADUser -Filter "SamAccountName -eq `"$un`"" -Properties MemberOf -ErrorAction SilentlyContinue
        $groups = Get-ADPrincipalGroupMembership $adUser -ErrorAction SilentlyContinue
        if (-not ($groups | Where-Object Name -eq "Domain Admins")) { Write-PodeJsonResponse -Value @{ error = "Access denied. Domain Admins only." }; return }
        $WebEvent.Session.Data.PendingUser = $un; Save-PodeSession
        $secrets = Get-TOTPSecrets
        if ($secrets.PSObject.Properties.Name -contains $un) {
            Write-PodeJsonResponse -Value @{ success = $true; nextStep = "totp" }
        } else {
            Write-PodeJsonResponse -Value @{ success = $true; nextStep = "setup" }
        }
    }
    Add-PodeRoute -Method Get -Path "/login/setup-data" -ScriptBlock {
        $un = $WebEvent.Session.Data.PendingUser
        if ([string]::IsNullOrEmpty($un)) { Write-PodeJsonResponse -Value @{ error = "Session expired." }; return }
        $secret = New-TOTPBase32Secret
        $WebEvent.Session.Data.PendingSecret = $secret; Save-PodeSession
        $otp = "otpauth://totp/ADUserEditor%3A$un`?secret=$secret&issuer=ADUserEditor"
        Write-PodeJsonResponse -Value @{ secret = $secret; otpauth = $otp }
    }
    Add-PodeRoute -Method Post -Path "/login/setup" -ScriptBlock {
        $body = [string]$WebEvent.Request.Body | ConvertFrom-Json
        $un = $WebEvent.Session.Data.PendingUser; $sec = $WebEvent.Session.Data.PendingSecret
        if ([string]::IsNullOrEmpty($un) -or [string]::IsNullOrEmpty($sec)) { Write-PodeJsonResponse -Value @{ error = "Session expired." }; return }
        if (-not (Test-TOTPCode -Base32Secret $sec -Code ([string]$body.code))) { Write-PodeJsonResponse -Value @{ error = "Invalid code. Try again." }; return }
        Save-TOTPSecret -Username $un -Secret $sec
        $WebEvent.Session.Data.LoggedIn = $true; $WebEvent.Session.Data.Username = $un
        $WebEvent.Session.Data.PendingUser = $null; $WebEvent.Session.Data.PendingSecret = $null
        Save-PodeSession
        Write-PodeJsonResponse -Value @{ success = $true }
    }
    Add-PodeRoute -Method Post -Path "/login/totp" -ScriptBlock {
        $body = [string]$WebEvent.Request.Body | ConvertFrom-Json
        $un = $WebEvent.Session.Data.PendingUser
        if ([string]::IsNullOrEmpty($un)) { Write-PodeJsonResponse -Value @{ error = "Session expired." }; return }
        $sec = (Get-TOTPSecrets).$un
        if (-not (Test-TOTPCode -Base32Secret $sec -Code ([string]$body.code))) { Write-PodeJsonResponse -Value @{ error = "Invalid code. Try again." }; return }
        $WebEvent.Session.Data.LoggedIn = $true; $WebEvent.Session.Data.Username = $un
        $WebEvent.Session.Data.PendingUser = $null; Save-PodeSession
        Write-PodeJsonResponse -Value @{ success = $true }
    }
    Add-PodeRoute -Method Get -Path "/logout" -ScriptBlock {
        $WebEvent.Session.Data.LoggedIn = $false; Save-PodeSession
        Move-PodeResponseUrl -Url "/login"
    }
    Add-PodeRoute -Method Get -Path "/" -ScriptBlock {
        Write-PodeFileResponse -Path "C:\ADUserEditor\public\index.html" -ContentType "text/html"
    }
    Add-PodeStaticRoute -Path "/public" -Source "C:\ADUserEditor\public"
    Add-PodeRoute -Method Get -Path "/api/users" -ScriptBlock {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        $users = Get-ADUser -Filter * -SearchBase "OU=Users,OU=Alex,DC=alex,DC=local" -ResultSetSize 1000 -ErrorAction SilentlyContinue | Select-Object -ExpandProperty SamAccountName
        if ($null -eq $users) { $users = @() }
        Write-PodeJsonResponse -Value @{ users = @($users) }
    }
    Add-PodeRoute -Method Get -Path "/api/user/:username" -ScriptBlock {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        $username = $WebEvent.Parameters["username"]
        $user = Get-ADUser -Filter "SamAccountName -eq `"$username`"" -Properties DisplayName,GivenName,Surname,Description,EmailAddress,Office,Title,TelephoneNumber,EmployeeNumber,Manager,Enabled,MemberOf,LockedOut -ErrorAction SilentlyContinue
        if (-not $user) { Write-PodeJsonResponse -Value @{ error = "User not found." }
        } else {
            $mn = ""
            if ($user.Manager) { $mgr = Get-ADUser -Identity $user.Manager -Properties DisplayName -ErrorAction SilentlyContinue; if ($mgr) { $mn=[string]$mgr.DisplayName } else { $mn=[string]$user.Manager } }
            $groups = Get-ADPrincipalGroupMembership $user -ErrorAction SilentlyContinue
            $sg = if ($groups) { ($groups|Where-Object GroupCategory -eq "Security"|Select-Object -ExpandProperty Name) -join ", " } else { "" }
            $dg = if ($groups) { ($groups|Where-Object GroupCategory -eq "Distribution"|Select-Object -ExpandProperty Name) -join ", " } else { "" }
            Write-PodeJsonResponse -Value @{ samAccountName=[string]$user.SamAccountName; firstName=[string]$user.GivenName; lastName=[string]$user.Surname; displayName=[string]$user.DisplayName; email=[string]$user.EmailAddress; phone=[string]$user.TelephoneNumber; employeeNumber=[string]$user.EmployeeNumber; title=[string]$user.Title; manager=$mn; managerDN=[string]$user.Manager; office=[string]$user.Office; description=[string]$user.Description; secGroups=$sg; distGroups=$dg; enabled=[bool]$user.Enabled; lockedOut=[bool]$user.LockedOut }
        }
    }
    Add-PodeRoute -Method Post -Path "/api/user/:username/update" -ScriptBlock {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        $username = $WebEvent.Parameters["username"]
        $raw = [string]$WebEvent.Request.Body
        if ([string]::IsNullOrWhiteSpace($raw)) { Write-PodeJsonResponse -Value @{ error = "Empty body." }; return }
        $b = $raw | ConvertFrom-Json; $managerDN = $null
        if (![string]::IsNullOrEmpty([string]$b.manager)) {
            $mi = [string]$b.manager
            $mgr = Get-ADUser -Filter "DisplayName -eq `"$mi`" -or SamAccountName -eq `"$mi`"" -Properties DistinguishedName -ErrorAction SilentlyContinue
            if (-not $mgr) { Write-PodeJsonResponse -Value @{ error = "Manager not found." }; return }
            if ($mgr -is [array]) { $mgr = $mgr[0] }
            if ($mgr.DistinguishedName -ne [string]$b.managerDN) { $managerDN = $mgr.DistinguishedName }
        }
        $adUser = Get-ADUser -Filter "SamAccountName -eq `"$username`"" -Properties * -ErrorAction SilentlyContinue
        if (-not $adUser) { Write-PodeJsonResponse -Value @{ error = "User not found." }; return }
        $params = @{ Identity = $adUser }
        $map = @{ GivenName=[string]$b.firstName; Surname=[string]$b.lastName; DisplayName=[string]$b.displayName; Description=[string]$b.description; EmailAddress=[string]$b.email; Office=[string]$b.office; Title=[string]$b.title; OfficePhone=[string]$b.phone }
        foreach ($k in $map.Keys) { if (![string]::IsNullOrEmpty($map[$k])) { $params[$k]=$map[$k] } }
        if (![string]::IsNullOrEmpty([string]$b.employeeNumber)) { $params["EmployeeNumber"]=[string]$b.employeeNumber }
        if ($null -ne $b.enabled) { $params["Enabled"]=[System.Convert]::ToBoolean($b.enabled) }
        if ($managerDN) { $params["Manager"]=$managerDN }
        $err = $null; try { Set-ADUser @params } catch { $err=[string]$_.Exception.Message }
        if ($err) { Write-PodeJsonResponse -Value @{ error=$err } } else { Write-PodeJsonResponse -Value @{ success=$true; message="User updated successfully." } }
    }
    Add-PodeRoute -Method Post -Path "/api/user/:username/password" -ScriptBlock {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        $username = $WebEvent.Parameters["username"]
        $body = [string]$WebEvent.Request.Body | ConvertFrom-Json; $pwd = [string]$body.password
        if ([string]::IsNullOrEmpty($pwd)) { Write-PodeJsonResponse -Value @{ error="Password cannot be empty." }; return }
        $err=$null; $sec=ConvertTo-SecureString $pwd -AsPlainText -Force
        Set-ADAccountPassword -Identity $username -NewPassword $sec -Reset -ErrorAction SilentlyContinue -ErrorVariable err
        if (-not $err -and $body.mustChange -eq $true) { Set-ADUser -Identity $username -ChangePasswordAtLogon $true -ErrorAction SilentlyContinue -ErrorVariable err }
        if ($err) { Write-PodeJsonResponse -Value @{ error=[string]$err[0].Exception.Message } } else { Write-PodeJsonResponse -Value @{ success=$true; message="Password reset successfully." } }
    }
    Add-PodeRoute -Method Post -Path "/api/user/:username/unlock" -ScriptBlock {
        Import-Module ActiveDirectory -ErrorAction SilentlyContinue
        $username = $WebEvent.Parameters["username"]
        $user = Get-ADUser -Filter "SamAccountName -eq `"$username`"" -Properties LockedOut -ErrorAction SilentlyContinue
        if (-not $user) { Write-PodeJsonResponse -Value @{ error="User not found." }; return }
        if (-not $user.LockedOut) { Write-PodeJsonResponse -Value @{ error="Account is not locked." }; return }
        $err=$null; Unlock-ADAccount -Identity $username -ErrorAction SilentlyContinue -ErrorVariable err
        if ($err) { Write-PodeJsonResponse -Value @{ error=[string]$err[0].Exception.Message } } else { Write-PodeJsonResponse -Value @{ success=$true; message="Account unlocked." } }
    }
    Add-PodeRoute -Method Get -Path "/api/empnum/check/:number" -ScriptBlock {
        $number=$WebEvent.Parameters["number"]; $trimmed=$number.TrimStart("0")
        if ([string]::IsNullOrEmpty($trimmed)) { Write-PodeJsonResponse -Value @{ inUse=$false }; return }
        $s1=New-Object System.DirectoryServices.DirectorySearcher
        $s1.Filter="(&(objectCategory=person)(objectClass=user)(employeeNumber=$trimmed))"
        $s1.PropertiesToLoad.Add("displayName") | Out-Null; $match=$s1.FindOne()
        if ($match) {
            $owner=[string]$match.Properties["displayName"][0]
            $s2=New-Object System.DirectoryServices.DirectorySearcher
            $s2.Filter="(&(objectCategory=person)(objectClass=user)(employeeNumber=*))"
            $s2.PropertiesToLoad.Add("employeeNumber") | Out-Null
            $nums=@($s2.FindAll()|ForEach-Object{$_.Properties["employeeNumber"][0]}|Where-Object{$_ -match "^\d+$"}|ForEach-Object{[int]$_})
            $c=[int]$trimmed; while($nums -contains $c){$c++}
            Write-PodeJsonResponse -Value @{ inUse=$true; owner=$owner; nextAvailable=$c.ToString().PadLeft($number.Length,"0") }
        } else { Write-PodeJsonResponse -Value @{ inUse=$false } }
    }
    Write-Host "AD User Editor running at http://localhost:8080" -ForegroundColor Green
}
