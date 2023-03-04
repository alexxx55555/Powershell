$testing = $false # Set to $false to Email Users. $true to email samples to administrators only (see $sampleEmails below)
$SearchBase="OU=Users,OU=Alex,DC=alex,DC=local"
$ExcludeList="'New Employees'|'Separated Employees'"   #in the form of "SubOU1|SubOU2|SubOU3" -- possibly needing single quote for OU's with spaces, separate OU's with pipe and double-quote the list.
$smtpServer="EX2019.alex.local"
$expireindays = 42 #number of days of soon-to-expire paswords. i.e. notify for expiring in X days (and every day until $negativedays)
$negativedays = -3 #negative number of days (days already-expired). i.e. notify for expired X days ago
$from = "Administrator <ITRobot@alex.com>"
$logging = $false # Set to $false to Disable Logging
$logNonExpiring = $false
$logFile = "c:\PS-pwd-expiry.csv" # ie. c:\mylog.csv
$adminEmailAddr = "vinokura@alex.com" #multiple addr allowed but MUST be independent strings separated by comma
$sampleEmails = 3 
# System Settings
$textEncoding = [System.Text.Encoding]::UTF8
$date = Get-Date -format yyyy-MM-dd #for logfile only
$starttime=Get-Date #need time also; don't use date from above

Write-Host "Processing `"$SearchBase`" for Password-Expiration-Notifications"
Write-Host "Testing Mode: $testing"

# Get Users From AD who are Enabled, Passwords Expire
Import-Module ActiveDirectory
Write-Host "Gathering User List"
$users = get-aduser -SearchBase $SearchBase -Filter {(enabled -eq $true) -and (passwordNeverExpires -eq $false)} -properties sAMAccountName, displayName, PasswordNeverExpires, PasswordExpired, PasswordLastSet, EmailAddress, lastLogon, whenCreated
Write-Host "Filtering User List"
$users = $users | Where-Object {$_.DistinguishedName -notmatch $ExcludeList}
$DefaultmaxPasswordAge = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

$countprocessed=${users}.Count
$samplesSent=0
$countsent=0
$countnotsent=0
$countfailed=0

#set max sampleEmails to send to $adminEmailAddr
if ( $sampleEmails -isNot [int]) {
    if ( $sampleEmails.ToLower() -eq "all") {
    $sampleEmails=$users.Count
    } #else use the value given
}

if (($testing -eq $true) -and ($sampleEmails -ge 0)) {
    Write-Host "Testing only; $sampleEmails email samples will be sent to $adminEmailAddr"
} elseif (($testing -eq $true) -and ($sampleEmails -eq 0)) {
    Write-Host "Testing only; emails will NOT be sent"
}

# Create CSV Log
if ($logging -eq $true) {
    #Always purge old CSV file
    Out-File $logfile
    Add-Content $logfile "`"Date`",`"SAMAccountName`",`"DisplayName`",`"Created`",`"PasswordSet`",`"DaystoExpire`",`"ExpiresOn`",`"EmailAddress`",`"Notified`""
}

# Process Each User for Password Expiry
foreach ($user in $users) {
    $dName = $user.displayName
    $sName = $user.sAMAccountName
    $emailaddress = $user.emailaddress
    $whencreated = $user.whencreated
    $passwordSetDate = $user.PasswordLastSet
    $sent = "" # Reset Sent Flag

    $PasswordPol = (Get-AduserResultantPasswordPolicy $user)
    # Check for Fine Grained Password
    if (($PasswordPol) -ne $null) {
        $maxPasswordAge = ($PasswordPol).MaxPasswordAge
    } else {
        # No FGPP set to Domain Default
        $maxPasswordAge = $DefaultmaxPasswordAge
    }

    #If maxPasswordAge=0 then same as passwordNeverExpires, but PasswordCannotExpire bit is not set
    if ($maxPasswordAge -eq 0) {
        Write-Host "$sName MaxPasswordAge = $maxPasswordAge (i.e. PasswordNeverExpires) but bit not set."
    }

    $expiresOn = $passwordsetdate + $maxPasswordAge
    $today = (get-date)

    if ( ($user.passwordexpired -eq $false) -and ($maxPasswordAge -ne 0) ) {   #not Expired and not PasswordNeverExpires
        $daystoexpire = (New-TimeSpan -Start $today -End $expiresOn).Days
    } elseif ( ($user.passwordexpired -eq $true) -and ($passwordSetDate -ne $null) -and ($maxPasswordAge -ne 0) ) {   #if expired and passwordSetDate exists and not PasswordNeverExpires
        # i.e. already expired
        $daystoexpire = -((New-TimeSpan -Start $expiresOn -End $today).Days)
    } else {
        # i.e. (passwordSetDate = never) OR (maxPasswordAge = 0)
        $daystoexpire="NA"
        #continue #"continue" would skip user, but bypass any non-expiry logging
    }

    #Write-Host "$sName DtE: $daystoexpire MPA: $maxPasswordAge" #debug

    # Set verbiage based on Number of Days to Expiry.
    Switch ($daystoexpire) {
        {$_ -ge $negativedays -and $_ -le "-1"} {$messageDays = "has expired"}
        "0" {$messageDays = "will expire today"}
        "1" {$messageDays = "will expire in 1 day"}
        default {$messageDays = "will expire in " + "$daystoexpire" + " days"}
    }

    # Email Subject Set Here
    $subject="Your password $messageDays"

    # Email Body Set Here, Note You can use HTML, including Images.
    $body="     
<img src='\\dc1\Applications\alex.jpg' width='343' height='66'></img>

<br>

        <p>Your Active Directory password for your <b>$sName</b> account $messageDays.  After expired, you will not be able to login until your password is changed.</p>


    <p><b><h1><font color='red'> Please change it as soon as possible! </b></p></h1></font>
    </br>

    <p><h3>To change your password, follow the method below:</p></h3>
   <h5></b> 
    <p>1.Log onto your computer as usual and make sure you are connected to the internet.</p>
	<p>2.Press Ctrl-Alt-Del and click on ""Change Password"". </p>
	<p>3.Fill in your old password and set a new password.  See the password requirements below.</p>
	<p>4.Press OK to return to your desktop.</p> 

<br>
<p><h3>The new password must meet the minimum requirements set forth in our corporate policies including:</p></h3>
	<p>1.It must be at least 5 characters long.</p>
	<p>2.It must contain at least one character from 3 of the 4 following groups of characters:</p>
		<p>A.Uppercase letters (A-Z)</p>
		<p>B.Lowercase letters (a-z)</p>
		<p>C.Numbers (0-9)</p>
		<p>D.Symbols (!@#$%^&*...)</p>
	<p>3.It cannot match any of your past 24 passwords.</p>
	<p>4.It cannot contain characters which match 3 or more consecutive characters of your username.</p>
	<p>5.You cannot change your password more often than once in a 24 hour period.</p>
</br>
<br>
</h5>

<p><h4>If you have any questions please contact our Support team.</p>

<p>Thanks,</p>
</h4>

<p><b><font color='green'><h2>Alex IT</b></p></font></h2></b>
   
    "

    # If testing-enabled and send-samples, then set recipient to adminEmailAddr else user's EmailAddress
    if (($testing -eq $true) -and ($samplesSent -lt $sampleEmails)) {
        $recipient = $adminEmailAddr
    } else {
        $recipient = $emailaddress
    }

    #if in trigger range, send email
    if ( ($daystoexpire -ge $negativedays) -and ($daystoexpire -lt $expireindays) -and ($daystoexpire -ne "NA") ) {
        # Send Email Message
        if (($emailaddress) -ne $null) {
            if ( ($testing -eq $false) -or (($testing -eq $true) -and ($samplesSent -lt $sampleEmails)) ) {
                try {
                    Send-Mailmessage -smtpServer $smtpServer -from $from -to $recipient -subject $subject -body $body -bodyasHTML -priority High -Encoding $textEncoding -ErrorAction Stop -ErrorVariable err
                } catch {
                    write-host "Error: Could not send email to $recipient via $smtpServer"
                    $sent = "Send fail"
                    $countfailed++
                } finally {
                    if ($err.Count -eq 0) {
                        write-host "Sent email for $sName to $recipient"
                        $countsent++
                        if ($testing -eq $true) {
                            $samplesSent++
                            $sent = "toAdmin"
                        } else { $sent = "Yes" }
                    }
                }
            } else {
                Write-Host "Testing mode: skipping email to $recipient"
                $sent = "No"
                $countnotsent++
            }
        } else {
            Write-Host "$dName ($sName) has no email address."
            $sent = "No addr"
            $countnotsent++
        }

        # If Logging is Enabled Log Details
        if ($logging -eq $true) {
            Add-Content $logfile "`"$date`",`"$sName`",`"$dName`",`"$whencreated`",`"$passwordSetDate`",`"$daystoExpire`",`"$expireson`",`"$emailaddress`",`"$sent`""
        }
    } else {
        #if ( ($daystoexpire -eq "NA") -and ($maxPasswordAge -eq 0) ) { Write-Host "$sName PasswordNeverExpires" } elseif ($daystoexpire -eq "NA") { Write-Host "$sName PasswordNeverSet" } #debug
        # Log Non Expiring Password
        if ( ($logging -eq $true) -and ($logNonExpiring -eq $true) ) {
            if ($maxPasswordAge -eq 0 ) {
                $sent = "NeverExp"
            } else {
                $sent = "No"
            }
            Add-Content $logfile "`"$date`",`"$sName`",`"$dName`",`"$whencreated`",`"$passwordSetDate`",`"$daystoExpire`",`"$expireson`",`"$emailaddress`",`"$sent`""
        }
    }

} # End User Processing

$endtime=Get-Date
$totaltime=($endtime-$starttime).TotalSeconds
$minutes="{0:N0}" -f ($totaltime/60)
$seconds="{0:N0}" -f ($totaltime%60)

Write-Host "$countprocessed Users from `"$SearchBase`" Processed in $minutes minutes $seconds seconds."
Write-Host "Email trigger range from $negativedays (past) to $expireindays (upcoming) days of user's password expiry date."
Write-Host "$countsent Emails Sent."
Write-Host "$countnotsent Emails skipped."
Write-Host "$countfailed Emails failed."

# sort the CSV file
if ($logging -eq $true) {
    Rename-Item $logfile "$logfile.old"
    import-csv "$logfile.old" | sort ExpiresOn | export-csv $logfile -NoTypeInformation
    Remove-Item "$logFile.old"
    Write-Host "CSV File created at ${logfile}."

    if ($testing -eq $true) {
        $body="<b><i>Testing Mode.</i></b><br>"
    } else {
        $body=""
    }

    $body+="
    CSV Attached for $date<br>
    $countprocessed Users from `"$SearchBase`" Processed in $minutes minutes $seconds seconds.<br>
    Email trigger range from $negativedays (past) to $expireindays (upcoming) days of user's password expiry date.<br>
    $countsent Emails Sent.<br>
    $countnotsent Emails skipped.<br>
    $countfailed Emails failed.
    "


    try {
        Send-Mailmessage -smtpServer $smtpServer -from $from -to $adminEmailAddr -subject "Password Expiry Logs" -body $body -bodyasHTML -Attachments "$logFile" -priority High -Encoding $textEncoding -ErrorAction Stop -ErrorVariable err
    } catch {
         write-host "Error: Failed to email CSV log to $adminEmailAddr via $smtpServer"
    } finally {
        if ($err.Count -eq 0) {
            write-host "CSV emailed to $adminEmailAddr"
        }
    }
}

