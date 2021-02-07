function Load-PDQConfig {
    <#
        .SYNOPSIS
            Loads PDQ Config

        .DESCRIPTION
            Loads PDQ Config, this is used by all functions

        .NOTES
            Author: Chris Bayliss | Caleb Bartle
            Version: 1.1
            Date: 2/6/2021
    #>
    if (!(Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\PSPDQ\config.json")) {
        Throw "PSPDQ Configuration file not found in `"C:\Program Files\WindowsPowerShell\Modules\PSPDQ\config.json", "please run Set-PSPDQConfig to configure module settings."
    }
    else {
        $global:config = Get-Content "C:\Program Files\WindowsPowerShell\Modules\PSPDQ\config.json" | ConvertFrom-Json

        $global:Server = $config.Server.PDQInventoryServer
        $global:DatabasePath = $config.DBPath.PDQInventoryDB
    }
}