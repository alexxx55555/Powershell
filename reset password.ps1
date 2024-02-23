# Prompt the user to enter their credentials
$credential = Get-Credential

# Reset the computer machine password using the entered credentials
Reset-ComputerMachinePassword -Credential $credential