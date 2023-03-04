Write-Host $env:COMPUTERNAME -ForegroundColor Magenta
$startTime=Get-Date;

Write-Host "Check #1 – Misplaced certificates in Trusted Root CA" -ForegroundColor Cyan
$check = Get-Childitem cert:\LocalMachine\root -Recurse | Where-Object {$_.Issuer -ne $_.Subject}

if(($check).count -gt 0){
Write-Host "Found" ($check).count "misplaced certificate(s) in Trusted Root CA:" -ForegroundColor yellow
$check | Select Issuer, Subject, Thumbprint | fl
$check | Move-Item -Destination Cert:\localmachine\CA -Force
Write-Host "Fixed!"
} else {
Write-Host "No misplaced certificate found in Trusted Root CA." -ForegroundColor Green
}

###################### 1 ###############

Write-Host "Check #2 - Misplaced Root CA certificates in Intermediate CA store" -ForegroundColor Cyan
$check = Get-ChildItem Cert:\localmachine\CA | Where-Object { $_.Issuer -eq $_.Subject }

if (($check).count -gt 0)
{
Write-Host "Found" ($check).count "misplaced Root CA certificate(s) in Intermediate CA store:" -ForegroundColor yellow
$check | Select Issuer, Subject, Thumbprint | fl
$check | Move-Item -Destination cert:\LocalMachine\root -Force
Write-Host "Fixed!"
}
else
{
Write-Host "No misplaced Root CA certificate found." -ForegroundColor Green
}


###################### 2 ###############

Write-Host "Check #3 - Root CA certificates in Personal Store" -ForegroundColor Cyan
$check = Get-Childitem cert:\LocalMachine\my -Recurse | Where-Object { $_.Issuer -eq $_.Subject }

if (($check).count -gt 0)
{
Write-Host "Found" ($check).count "Root CA certificate(s) in Personal Store:" -ForegroundColor yellow
$check | Select FriendlyName, Issuer, Subject, Thumbprint | fl
$check | Move-Item -Destination cert:\LocalMachine\root -Force
Write-Host "Fixed!"
}
else
{
Write-Host "No Root CA certificate(s) found in Personal Store." -ForegroundColor Green
}


###################### 3 ###############


Write-Host "Check #4 - Duplicates in Trusted Root CA" -ForegroundColor Cyan
$check = Get-Childitem cert:\LocalMachine\root | Group-Object -Property Thumbprint | Where-Object {$_.Count -gt 1}
if(($check).count -gt 0){
Write-Host "Found" ($check).count "duplicated Trusted Root CA certificate(s):" -ForegroundColor yellow
$check.group | Select Issuer, Subject, Thumbprint | fl

foreach ($obj in $check){

$obj.Group | select -First ($obj.Group.Count -1) |Remove-Item }

Write-Host "Fixed!"

} else {
Write-Host "No duplicated certificate(s) found." -ForegroundColor Green}


###################### 4 ###############

Write-Host "Check #5 - Duplicated Friendly Name" -ForegroundColor Cyan
$check = Get-Childitem cert:\LocalMachine\my | Group-Object -Property FriendlyName | Where-Object { $_.Count -gt 1 }

if (($check).count -gt 0)
{
Write-Host "Found" ($check).count "certificate(s) with the same Friendly Name:" -ForegroundColor yellow
$check | Select-Object -ExpandProperty Group | Select FriendlyName, Issuer, Subject, Thumbprint | fl
$obj = $check | Select-Object -ExpandProperty Group
foreach ($item in $obj)
{
$x = ($item | select Thumbprint)
($item).FriendlyName = "$x"
}
Write-Host "Fixed!"
}
else
{
Write-Host "No duplicated certificate(s) found." -ForegroundColor Green
}

###################### 5 ###############

Write-Host "Check #6 - Expired certificates in Root, Intermediate and Personal Store" -ForegroundColor Cyan
$limit = Get-Date
$checkMy = Get-ChildItem Cert:\LocalMachine\My | ?{ $_.NotAfter -le $limit }
$checkRoot = Get-ChildItem Cert:\LocalMachine\Root | ?{ $_.NotAfter -le $limit }
$checkCA = Get-ChildItem Cert:\LocalMachine\CA | ?{ $_.NotAfter -le $limit }

if (($checkMy).count -gt 0)
{
Write-Host "Found" ($checkMy).count "expired certificate(s) in Personal store:" -ForegroundColor yellow
$checkMy | Select Issuer, Subject, Thumbprint, NotAfter | fl
$checkMy | Remove-Item
Write-Host "Fixed!"
}
else
{
Write-Host "No expired certificates in the Personal store." -ForegroundColor Green
}

if (($checkRoot).count -gt 0)
{
Write-Host "Found" ($checkRoot).count "expired certificate(s) in Root CA store:" -ForegroundColor yellow
$checkRoot | Select Issuer, Subject, Thumbprint, NotAfter | fl
$checkRoot | Remove-Item
Write-Host "Fixed!"
}
else
{
Write-Host "No expired certificates in the Root CA Store." -ForegroundColor Green
}

if (($checkCA).count -gt 0)
{
Write-Host "Found" ($checkCA).count "expired certificate(s) in Intermediate CA store:" -ForegroundColor yellow
$checkCA | Select Issuer, Subject, Thumbprint, NotAfter | fl
$checkCA | Remove-Item
Write-Host "Fixed!"
}
else
{
Write-Host "No expired certificates in the Intermediate CA Store." -ForegroundColor Green
}

###################### 6 ###############

Write-Host "Check #7 – More than 100 certificates in Trusted Root CA store" -ForegroundColor Cyan
$check = (Get-Childitem cert:\LocalMachine\root).count

if($check -gt 100){
Write-Host "Found" $check "Trusted Root CA certificates." -ForegroundColor yellow
$check | Select Issuer, Subject, Thumbprint | fl
} else {
Write-Host "Found" $check "Trusted Root CA certificates." -ForegroundColor Green
}

###################### 7 ###############


$endTime=Get-Date;
$totalTime= [math]::round(($endTime - $startTime).TotalSeconds,2)
Write-Host "Execution time:" $totalTime "seconds." -ForegroundColor Cyan
