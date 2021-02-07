function Set-PSPDQConfig {
    <#
        .SYNOPSIS
            Sets configuration for PSPDQ module.

        .DESCRIPTION
            Sets sever hostname and database path information for PDQ Deploy and Inventory to json file within $env:APPDATA
            By default, database files will be located within:
            PDQ Deploy: "C:\ProgramData\Admin Arsenal\PDQ Deploy\Database.db"
            PDQ Inventory: "C:\ProgramData\Admin Arsenal\PDQ Inventory\Database.db"

            Be sure to set the database path as the LOCAL path to the file. As in "Drive:\file\path" NOT "\\UNCpath\file\path"

        .PARAMETER PDQDeployServer
            Hostname or FQDN or PDQ Deploy server

        .PARAMETER PDQInventoryServer
            Hostname or FQDN or PDQ Inventory server

        .PARAMETER PDQDeployDBPath
            Full LOCAL path of PDQ Deploy database

        .PARAMETER PDQInventoryDBPath
            Full LOCAL path of PDQ Inventory database

        .EXAMPLE
            Set-PSPDQConfig -PDQDeployServer PDQSERVER1 -PDQInventoryServer PDQSERVER2 -PDQDeployDBPath "C:\ProgramData\PDQ Deploy\Database.db" -PDQInventoryDBPath "C:\ProgramData\PDQ Inventory\Database.db"

        .NOTES
            Author: Chris Bayliss | Caleb Bartle
            Updated By Caleb Bartle
            Version: 1.1
            Date: 2/6/2021
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$PDQDeployServer,

        [Parameter(Mandatory = $true)]
        [string]$PDQInventoryServer,

        [Parameter(Mandatory = $true)]
        [string]$PDQDeployDBPath,

        [Parameter(Mandatory = $true)]
        [string]$PDQInventoryDBPath
    )
    
    process {
        if (!(Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\PSPDQ")) {
            New-Item -Path "C:\Program Files\WindowsPowerShell\Modules\PSPDQ\config.json" -Force
        }

        $conf = @{
            "Server" = @{
                "PDQDeployServer"    = "$PDQDeployServer"
                "PDQInventoryServer" = "$PDQInventoryServer"
            }

            "DBPath" = @{
                "PDQDeployDB"    = "$PDQDeployDBPath"
                "PDQInventoryDB" = "$PDQInventoryDBPath"
            }
        } | ConvertTo-Json

        $conf | Out-File "C:\Program Files\WindowsPowerShell\Modules\PSPDQ\config.json" -Force
    }
}