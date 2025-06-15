<#
.SYNOPSIS
    Copies all static distribution-group memberships from one user (source)
    to another (target) in Exchange Online and prints an end-of-run report
    that includes a table of the groups successfully copied.

.PARAMETER SourceUser
    SMTP address of the source mailbox.

.PARAMETER TargetUser
    SMTP address of the target mailbox.

.PARAMETER ReportPath
    Optional file path for a CSV audit report.

.EXAMPLE
    .\Copy-DGMembership.ps1 -SourceUser alice@contoso.com `
                            -TargetUser bob@contoso.com `
                            -Verbose
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory)][string]$SourceUser,
    [Parameter(Mandatory)][string]$TargetUser,
    [string]$ReportPath
)

# Lists for reporting
$added     = [System.Collections.Generic.List[string]]::new()
$skipped   = [System.Collections.Generic.List[string]]::new()
$noManager = [System.Collections.Generic.List[string]]::new()

try {
    Write-Verbose "Connecting to Exchange Online…"
    Connect-ExchangeOnline -ShowBanner:$false

    # Resolve recipients
    $src = Get-Recipient -Identity $SourceUser -ErrorAction Stop
    $tgt = Get-Recipient -Identity $TargetUser -ErrorAction Stop

    Write-Verbose "Retrieving DGs that already contain $SourceUser…"
    $groups = Get-DistributionGroup -ResultSize Unlimited `
        -Filter "Members -eq '$($src.Guid)'" |
        Where-Object RecipientTypeDetails -eq 'MailUniversalDistributionGroup'

    foreach ($g in $groups) {

        # Skip “approval required & no manager”
        if ($g.MemberJoinRestriction -eq 'ApprovalRequired' -and -not $g.ManagedBy) {
            $noManager.Add($g.PrimarySmtpAddress)
            Write-Verbose "Skipped (needs approval, no manager): $($g.PrimarySmtpAddress)"
            continue
        }

        if ($PSCmdlet.ShouldProcess($g.PrimarySmtpAddress,
                                    "Add $TargetUser as member")) {
            try {
                Add-DistributionGroupMember -Identity $g.Guid `
                                            -Member  $tgt.Guid `
                                            -ErrorAction Stop
                $added.Add($g.PrimarySmtpAddress)
                Write-Verbose "Added $TargetUser to $($g.PrimarySmtpAddress)"
            }
            catch [Microsoft.Exchange.Management.RecipientTasks.RecipientTaskException] {
                if ($_.Exception.Message -match 'already .* member') {
                    $skipped.Add($g.PrimarySmtpAddress)
                    Write-Verbose "$TargetUser already in $($g.PrimarySmtpAddress); skipped."
                } else {
                    throw
                }
            }
        }
    }

} finally {
    Write-Verbose "Disconnecting from Exchange Online…"
    Disconnect-ExchangeOnline -Confirm:$false
}

# ── Summary ────────────────────────────────────────────────────────────────────
Write-Host "`n===== Membership-Copy Summary =====" -ForegroundColor Cyan
Write-Host ("Added   : {0}" -f $added.Count)
Write-Host ("Skipped : {0}" -f $skipped.Count)
Write-Host ("NoMgr   : {0}" -f $noManager.Count)
Write-Host "====================================`n" -ForegroundColor Cyan

# NEW: Display the “added” groups in a nice console table
if ($added.Count) {
    $added |
        Sort-Object |
        ForEach-Object { [pscustomobject]@{ 'Group (Added)' = $_ } } |
        Format-Table -AutoSize
} else {
    Write-Host "No groups were copied." -ForegroundColor Yellow
}

# Optional CSV audit report
if ($ReportPath) {
    $report = @()
    $report += $added    | ForEach-Object { [pscustomobject]@{Group=$_;Action='Added'} }
    $report += $skipped  | ForEach-Object { [pscustomobject]@{Group=$_;Action='AlreadyMember'} }
    $report += $noManager| ForEach-Object { [pscustomobject]@{Group=$_;Action='ApprovalRequired_NoManager'} }
    $report | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nCSV report written to $ReportPath"
}

Write-Host "`nCopy operation complete."
