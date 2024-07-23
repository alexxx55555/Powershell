# Connect to Microsoft Graph
Connect-MgGraph -Scopes "AuditLog.Read.All"

# Prompt for the user principal name
$userPrincipalName = Read-Host -Prompt "Enter the user principal name (e.g., user@aquasec.com)"

# Get the audit logs for group removals
$auditLogs = Get-MgAuditLogDirectoryAudit -Filter "activityDisplayName eq 'Remove member from group' and targetResources/any(r:r/userPrincipalName eq '$userPrincipalName')"

# Initialize an array to store the log details
$logDetails = @()

# Extract and collect detailed information
foreach ($log in $auditLogs) {
    foreach ($resource in $log.targetResources) {
        if ($resource.modifiedProperties) {
            foreach ($property in $resource.modifiedProperties) {
                if ($property.displayName -eq "Group.DisplayName") {
                    $logDetail = [PSCustomObject]@{
                        Timestamp        = $log.activityDateTime 
                        OldValue         = $property.oldValue
                    }
                    $logDetails += $logDetail
                }
            }
        }
    }
}

# Export the details to a CSV file
$logDetails | Select-Object Timestamp,OldValue | Export-Csv -Path "c:\AuditLogDetails.csv" -NoTypeInformation
