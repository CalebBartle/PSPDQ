# PSPDQ V1.1.0 (Beta)

This is a continued fork from the Archived version listed here: https://github.com/sysgoblin/PSPDQ/
This module update includes several changes and is now a dedicated fork.

A powershell module for PDQ Deploy and Inventory administration and querying.

It can be utilised for querying the PDQ Sqlite db's directly without needing to load, or install the PDQ Deploy and Inventory client software.

Cmdlets are also included for starting computer or collection scans, as well as deploying named packages from within Powershell. (Please note, these cmdlets will require PDQ Deploy and Inventory to be installed locally as client or server)

## Installation
### Using Git
```Powershell
git clone https://github.com/CalebBartle/PSPDQ/
cd PSPDQ
Import-Module .\PSPDQ.psm1
```
### Install from PSGallery
```Powershell
Install-Module -Name PSPDQ
```

If you don't have PDQ Deploy/Inventory installed you may also need to install sqlite3. `https://www.sqlite.org/download.html`

The first cmdlet you should run is: `Set-PSPDQConfig` to configure the PDQ Deploy and Inventory server information.
```Powershell
Set-PSPDQConfig -PDQDeployServer PDQSERVER1 -PDQInventoryServer PDQSERVER2 -PDQDeployDBPath "C:\ProgramData\PDQ Deploy\Database.db" -PDQInventoryDBPath "C:\ProgramData\PDQ Inventory\Database.db"
```
**Database paths should be LOCAL to the server**

## Examples
Get the last 10 deployments and their status:
```powershell
Get-PDQDeployment -Recent 10
```

Get the basic computer details of each computer the last 10 deployments went to:
```powershell
Get-PDQDeployment -Recent 10 | Get-PDQComputer
```
Get basic details on a computer and see if it's online:
```powershell
Get-PDQComputer -Computer WK01 -Properties IsOnline
```

Get the applications installed on some computers:
```powershell
Get-PDQComputerApplications -Computer WK01, WK02
```

Or maybe get the computers from the past 100 deployments and then get the patches for each that were installed in the past 3 days because why not?
```powershell
Get-PDQDeployment -Recent 100 | Get-PDQHotFix | ? InstalledOn -le (Get-Date).AddDays(-3)
```

## Available Commands
```powershell

CommandType     Name                                               Version    Source
-----------     ----                                               -------    ------
Function        Get-PDQCollection                                  1.1.0      PSPDQ
Function        Get-PDQCollectionMembers                           1.1.0      PSPDQ
Function        Get-PDQComputer                                    1.1.0      PSPDQ
Function        Get-PDQComputerApplications                        1.1.0      PSPDQ
Function        Get-PDQDeployment                                  1.1.0      PSPDQ
Function        Get-PDQDeploymentSteps                             1.1.0      PSPDQ
Function        Get-PDQHotFixes                                    1.1.0      PSPDQ
Function        Get-PDQPackage                                     1.1.0      PSPDQ
Function        Get-PDQSchedule                                    1.1.0      PSPDQ
Function        Get-PDQScheduleTargets                             1.1.0      PSPDQ
Function        Get-PDQVariable                                    1.1.0      PSPDQ
Function        Get-PSPDQConfig                                    1.1.0      PSPDQ
Function        Install-PDQPackage                                 1.1.0      PSPDQ
Function        Load-PDQConfig                                     1.1.0      PSPDQ
Function        Set-PDQVariable                                    1.1.0      PSPDQ
Function        Set-PSPDQConfig                                    1.1.0      PSPDQ
Function        Start-PDQCollectionScan                            1.1.0      PSPDQ
Function        Start-PDQComputerScan                              1.1.0      PSPDQ


```
