# Set the user mailbox you want to convert to a shared mailbox
$userMailbox = "user@example.com"

# Connect to Exchange Online PowerShell
Connect-ExchangeOnline

# Convert the user mailbox to a shared mailbox
Set-Mailbox -Identity $userMailbox -Type Shared

Write-Host "User mailbox $($userMailbox) has been converted to a shared mailbox."