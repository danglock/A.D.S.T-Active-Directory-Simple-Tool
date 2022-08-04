# ADST - Active Directory Simple Tool

**ADST** is a research and management tool developed by Swiss students based on the functionalities of the Microsoft Active Directory LDAP directory and Azure Active Directory.


- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Commands](#commands)






# Requirements


For a more complete use, install the following modules:




- [RSAT (Remote Server Administration Tools)]()
```PowerShell
Install-WindowsFeature RSAT-AD-PowerShell
```
- [EXO V2](https://docs.microsoft.com/en-us/powershell/exchange/exchange-online-powershell-v2#:~:text=To%20install%20the%20EXO%20V2,module%20from%20the%20PowerShell%20Gallery.), PowerShell command :
```PowerShell
Install-Module ExchangeOnlineManagement
```
> Il sera peut-être nécessaire d'adapter les clés de registres



# Installation
<h3><strong>Windows </strong>&nbsp;<img src="https://cdn.icon-icons.com/icons2/1488/PNG/512/5314-windows_102509.png" alt="" width="20" height="20" /></h3>

```
git clone https://github.com/danglock/A.D.S.T-Active-Directory-Simple-Tool/archive/refs/heads/main.zip
```
[Download the repository](https://github.com/danglock/A.D.S.T-Active-Directory-Simple-Tool/archive/refs/heads/main.zip)


# Usage

Launch **launch.bat** file


## Commands

- [Info commands](#info-commands)
- [Utility commands](#utility-commands)
- [Azure AD commands](#azure-ad-commands)


### Info commands
|**Command**|**Description**|
|:------|:----------|
| help  | List all commands of the tool
|InfoUser|Return user information from his SamAccountName|
|find   |Find the SamAccountName of a user using his name or firstname
|find_dep|Find the department of a user
|find_bydep|List all users of a department

### Utility Commands
|**Command**|**Description**|
|:------|:----------|
|AllUsers|Returns all users in Active Directory
|get_password|Returns a random password
|check_sam|Returns True if SamAccountName is already used
|powershell|Open a PowerShell shell

### Azure AD commands
|**Command**|**Description**|
|:------|:----------|
|Bouffe!|Synchronizes AD and AAD

## Coming soon

- Bulk operations commands (export/import users...)
- Copy of users
- Vulnerability scan


***
Version = v2
