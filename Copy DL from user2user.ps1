# Connect to Exchange Online
Connect-ExchangeOnline

$sourceUser = Read-Host "Enter the source user email"
$targetUser = Read-Host "Enter the target user email"

# Get all distribution groups
$allDistributionGroups = Get-DistributionGroup -ResultSize Unlimited | Where-Object { $_.RecipientTypeDetails -eq 'MailUniversalDistributionGroup' }

# Filter the groups where the source user is a member
$sourceGroups = @()
foreach ($group in $allDistributionGroups) {
    try {
        # Skip groups with MemberJoinRestriction set to ApprovalRequired and no manager
        if ($group.MemberJoinRestriction -eq "ApprovalRequired" -and -not $group.ManagedBy) {
            Write-Warning "Skipping group $($group.PrimarySmtpAddress) due to MemberJoinRestriction and no manager."
            continue
        }
        
        $members = Get-DistributionGroupMember -Identity $group.PrimarySmtpAddress
        if ($members | Where-Object { $_.PrimarySmtpAddress -eq $sourceUser }) {
            $sourceGroups += $group
        }
    } catch {
        Write-Warning "Failed to process group: $($group.PrimarySmtpAddress). Error: $_"
    }
}

# Add target user to each distribution group
foreach ($group in $sourceGroups) {
    try {
        # Check if the target user is already a member
        $members = Get-DistributionGroupMember -Identity $group.PrimarySmtpAddress
        if ($members | Where-Object { $_.PrimarySmtpAddress -eq $targetUser }) {
            Write-Warning "The recipient $targetUser is already a member of the group $($group.PrimarySmtpAddress). Skipping."
        } else {
            Add-DistributionGroupMember -Identity $group.PrimarySmtpAddress -Member $targetUser
            Write-Output "Added $targetUser to group $($group.PrimarySmtpAddress)."
        }
    } catch {
        Write-Warning "Failed to add member to group: $($group.PrimarySmtpAddress). Error: $_"
    }
}

# Disconnect from Exchange Online
Disconnect-ExchangeOnline -Confirm:$false

Write-Output "Processed distribution list memberships from $sourceUser to $targetUser."
