# PowerShell IT Administration Scripts

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://github.com/alexxx55555/Powershell/graphs/commit-activity)

A comprehensive collection of PowerShell scripts designed for IT administrators to automate and manage Active Directory, Azure AD, Exchange Online, Office 365, and system administration tasks.

## 📋 Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Script Categories](#script-categories)
  - [Active Directory User Management](#active-directory-user-management)
  - [Computer Management](#computer-management)
  - [Group Management](#group-management)
  - [Exchange & Office 365 Management](#exchange--office-365-management)
  - [Account Operations](#account-operations)
  - [Password Management](#password-management)
  - [System Administration & Utilities](#system-administration--utilities)
  - [Automation & Integration](#automation--integration)
- [Usage](#usage)
- [Examples](#examples)
- [Contributing](#contributing)
- [Security](#security)
- [License](#license)

## ✨ Features

- 🔐 Comprehensive Active Directory user and computer management
- 👥 Group membership and distribution list automation
- 📧 Exchange and Office 365 mailbox management
- 🔑 Password policies and expiration notifications
- 🖥️ System information and hardware inventory scripts
- 🔄 Automated user lifecycle management (onboarding/offboarding)
- 📊 Reporting and auditing capabilities
- 🎨 GUI-based tools for common administrative tasks

## 📦 Prerequisites

Before using these scripts, ensure you have the following installed:

- **PowerShell 5.1** or later (Windows PowerShell)
- **PowerShell 7+** (PowerShell Core) - recommended for cross-platform support

### Required Modules

Depending on which scripts you use, you may need the following PowerShell modules:

```powershell
# Active Directory management
Install-Module -Name ActiveDirectory

# Azure AD management
Install-Module -Name AzureAD

# Exchange Online management
Install-Module -Name ExchangeOnlineManagement

# Microsoft Graph (for modern Azure AD operations)
Install-Module -Name Microsoft.Graph
```

### Permissions

Most scripts require appropriate administrative permissions:
- **Domain Admin** or delegated rights for Active Directory operations
- **Exchange Admin** for mailbox management
- **Global Admin** or appropriate roles for Azure AD/Office 365 operations

## 🚀 Installation

1. Clone this repository:
```powershell
git clone https://github.com/alexxx55555/Powershell.git
cd Powershell
```

2. Set execution policy (if needed):
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

3. Import required modules for your environment:
```powershell
Import-Module ActiveDirectory
Import-Module ExchangeOnlineManagement
```

## 📂 Script Categories

### Active Directory User Management

Scripts for creating, modifying, and managing AD user accounts.

| Script | Description |
|--------|-------------|
| `Create AD User.ps1` | Interactive AD user creation with validation |
| `Create AD User With Auto Password.ps1` | Creates AD users with automatically generated passwords |
| `Create AD User With Auto Password GUI.ps1` | GUI version of automated user creation |
| `Create AD Users from CSV/Create AD Users from CSV.ps1` | Bulk user creation from CSV file |
| `Create Users from CSV file with report/Add Users from CSV file with report.ps1` | Bulk user creation with detailed reporting |
| `Create User+Mailbox/Create User+Mailbox.ps1` | Creates AD user and Exchange mailbox simultaneously |
| `Create-ADUser-From-n8n.ps1` | Creates AD user from n8n automation webhook |
| `Check AD user details.ps1` | Displays comprehensive user information |
| `Check if user exist in Active Directory/Check if user exist in Active Directory.ps1` | Checks for user existence in AD |
| `checkUser.ps1` / `Scripts/checkUser.ps1` | Quick user lookup and information display |
| `User Info.ps1` / `user info.ps1` | Retrieves detailed user information |
| `Connected user.ps1` | Shows currently connected/logged-in users |
| `Lastlogon.ps1` | Reports last logon times for users |
| `Find Locked User.ps1` | Finds and displays locked user accounts |
| `Enabled users.ps1` | Lists all enabled user accounts |
| `Delete user.ps1` | GUI tool for safely deleting AD users |
| `Remove AD user from CSV/Remove AD user from CSV.ps1` | Bulk user deletion from CSV |
| `restore user gui.ps1` | GUI tool for restoring deleted users |
| `offboarding.ps1` | Comprehensive user offboarding automation |

### Computer Management

Scripts for managing computer objects in Active Directory.

| Script | Description |
|--------|-------------|
| `Computer scripts/Create New Computer from CSV file.ps1` | ✨ Creates computer objects from CSV with validation |
| `Computer scripts/Remove Computer from AD with CSV File.ps1` | ✨ Removes computer objects with safety checks |
| `computer info.ps1` | Retrieves detailed computer information |
| `GetUserLaptopAssignments.ps1` | Shows laptop assignments by user |
| `Restart-PC.ps1` | Remote computer restart utility |

### Group Management

Scripts for managing security groups, distribution lists, and group membership.

| Script | Description |
|--------|-------------|
| `Add users to groups.ps1` | ✨ GUI tool for adding users to AD groups |
| `Add user as owner to groups in Azure Ad.ps1` | Adds users as group owners in Azure AD |
| `Add Users To SG O365.ps1` | Adds users to Office 365 security groups |
| `Create group Gui.ps1` | GUI tool for creating AD groups |
| `Create DL from csv file office 365.ps1` | ✨ Creates Office 365 distribution groups from CSV |
| `Create DL from csv file exchange.ps1` | Creates Exchange distribution lists from CSV |
| `DL form1.ps1` / `DL 2.ps1` / `DL with 1 user.ps1` | Distribution list management utilities |
| `copy users from one group to another gui.ps1` | GUI tool for copying group memberships |
| `Copy DL from user2user.ps1` / `Copy DL from user2user1.ps1` | Copies distribution list memberships between users |
| `Empty groups.ps1` | Identifies and reports empty groups |
| `Group that user removed from.ps1` | Tracks group membership changes |
| `Search user of DL.ps1` | Searches for users in distribution lists |

### Exchange & Office 365 Management

Scripts for managing Exchange and Office 365 services.

| Script | Description |
|--------|-------------|
| `Convert office 365 mailbox to shared mailbox.ps1` | Converts user mailboxes to shared mailboxes |
| `Booking room allowed for certain people.ps1` | Configures room mailbox permissions |
| `Skype for all.ps1` | Enables Skype for Business for users |
| `OST Fix.ps1` | Repairs Outlook OST file issues |
| `Scripts/TeamsFix.ps1` | Troubleshoots Microsoft Teams issues |
| `Scripts/PSTBlock.ps1` | Manages PST file restrictions |

### Account Operations

Scripts for enabling, disabling, and unlocking user accounts.

| Script | Description |
|--------|-------------|
| `Enable account.ps1` | ✨ Enhanced script to enable disabled accounts |
| `Disable account.ps1` | ✨ Enhanced script to disable accounts with confirmation |
| `Unlock account.ps1` | ✨ Enhanced script to unlock locked accounts |
| `Disable users after 90 days.ps1` | Automatically disables inactive user accounts |

### Password Management

Scripts for password policies, resets, and notifications.

| Script | Description |
|--------|-------------|
| `Password expiry email notification.ps1` | Sends automated password expiry notifications |
| `Password generetor.ps1` | GUI tool for generating secure passwords |
| `reset password.ps1` | Password reset utility |
| `Reset Password Gui.ps1` | GUI-based password reset tool |

### System Administration & Utilities

General system administration and utility scripts.

| Script | Description |
|--------|-------------|
| `Chocolatey.ps1` | Installs and configures Chocolatey package manager |
| `Winget.ps1` | Interactive Windows Package Manager (winget) installer |
| `Upgrade Modules.ps1` | Updates PowerShell modules to latest versions |
| `Recycle Bin Script.ps1` | Manages Active Directory recycle bin |
| `Certificate Check.ps1` | Checks certificate expiration dates |
| `Lenovo-info.ps1` | Retrieves Lenovo hardware warranty and specifications |
| `Info.ps1` | General system information gathering |
| `Report.ps1` | Generates various administrative reports |
| `Scripts/UpdateMTU.ps1` | Updates network MTU settings |
| `Scripts/USB_Allow-User.ps1` | Manages USB device permissions |
| `lock pic.ps1` | Lock screen customization utility |

### Automation & Integration

Scripts designed for automation workflows and integration with other systems.

| Script | Description |
|--------|-------------|
| `Create-ADUser-From-n8n.ps1` | Creates AD user from n8n workflow |
| `Create-JCUser-From-n8n.ps1` | Creates JumpCloud user from n8n workflow |
| `Microsoft.PowerShell_profile.ps1` | PowerShell profile customization |

### Count & Reporting

Scripts for counting and reporting on AD objects.

| Script | Description |
|--------|-------------|
| `Count number of users in AD/Count number of users in AD.ps1` | Counts total users in Active Directory |
| `Count number of users in AD/count.ps1` | Alternative user counting script |
| `Count number of users in OU.ps1` | Counts users in specific organizational unit |

## 💡 Usage

Most scripts can be run directly from PowerShell:

```powershell
# Run a script
.\ScriptName.ps1

# Run a script with parameters
.\Enable account.ps1 -Username "jdoe"

# Run a script with WhatIf (safe mode - no changes made)
.\Computer scripts\Remove Computer from AD with CSV File.ps1 -WhatIf

# Get help for a script
Get-Help .\ScriptName.ps1 -Full
```

## 📚 Examples

### Example 1: Enable a Disabled Account

```powershell
# Interactive mode (prompts for username)
.\Enable account.ps1

# Direct mode with username parameter
.\Enable account.ps1 -Username "jdoe"
```

### Example 2: Create Users from CSV

```powershell
# Create multiple users from CSV file
.\Create AD Users from CSV\Create AD Users from CSV.ps1 -CsvPath "C:\Users\Admin\newusers.csv"
```

### Example 3: Create Distribution Group in Office 365

```powershell
# Create DL and add members from CSV
.\Create DL from csv file office 365.ps1 -GroupName "Sales Team" -GroupAlias "sales" -CsvPath "C:\members.csv"
```

### Example 4: Create Computer Objects

```powershell
# Test what would happen (WhatIf mode)
.\Computer scripts\Create New Computer from CSV file.ps1 -WhatIf

# Actually create the computers
.\Computer scripts\Create New Computer from CSV file.ps1 -CsvPath "C:\computers.csv"
```

### Example 5: Bulk User Offboarding

```powershell
# Run comprehensive offboarding process
.\offboarding.ps1
# Prompts for username, then:
# - Disables account
# - Resets password
# - Removes from groups
# - Moves to Leavers OU
# - Archives mailbox
# - Sends notifications
```

## 🔒 Security

### Best Practices

1. **Never hardcode credentials** in scripts. Use `Get-Credential` or secure credential storage.
2. **Test scripts in a non-production environment** first.
3. **Use `-WhatIf` parameter** on scripts that support it to preview changes.
4. **Review CSV files** before bulk operations to prevent unintended changes.
5. **Audit script execution** by enabling PowerShell logging.
6. **Restrict script access** to authorized administrators only.

### Security Notes

- Scripts marked with ✨ have been recently enhanced with comprehensive error handling and validation
- Many scripts include built-in safety checks (duplicate detection, existence validation, etc.)
- Destructive operations (delete, disable, remove) include confirmation prompts
- All enhanced scripts include detailed comment-based help

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/AmazingFeature`)
3. **Commit** your changes (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Open** a Pull Request

### Contribution Guidelines

- Follow PowerShell best practices
- Include comment-based help for all scripts
- Add error handling with try/catch blocks
- Use approved PowerShell verbs for function names
- Test scripts thoroughly before submitting
- Update README.md with new scripts

## 📝 Script Documentation

All enhanced scripts include comprehensive comment-based help. Access it using:

```powershell
Get-Help .\ScriptName.ps1 -Full
Get-Help .\ScriptName.ps1 -Examples
Get-Help .\ScriptName.ps1 -Parameter ParameterName
```

## 🐛 Known Issues

- Some legacy scripts may have hardcoded domain names (alex.local) - update for your environment
- GUI scripts require Windows PowerShell (not PowerShell Core)
- Exchange scripts require appropriate remote connection setup

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👤 Author

**Alex**

- GitHub: [@alexxx55555](https://github.com/alexxx55555)

## 🙏 Acknowledgments

- Thanks to all contributors who help improve these scripts
- Microsoft PowerShell Team for excellent documentation
- IT Administration community for best practices and feedback

## 📞 Support

If you encounter issues or have questions:

1. Check the script's built-in help: `Get-Help .\ScriptName.ps1 -Full`
2. Review the [Issues](https://github.com/alexxx55555/Powershell/issues) page
3. Open a new issue with detailed information about your problem

---

**Note:** Always test scripts in a non-production environment before deploying to production. Many scripts have been recently enhanced (marked with ✨) with improved error handling, validation, and documentation.

**Last Updated:** 2025-01-22
