﻿Import-Csv 'C:\AD User\users.csv' | Foreach-Object {Remove-ADUser -Identity $_.SamAccountName -Confirm:$true }