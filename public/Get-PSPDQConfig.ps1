function Get-PSPDQConfig {
<#
        .SYNOPSIS
            Get PSPDQ Configuration
    
        .DESCRIPTION
            Retreives PSPDQ Configuration

        .EXAMPLE
            Get-PSPDQConfig
    
            Server                                                         DBPath                                                                                                                                
            ------                                                         ------                                                                                                                                
            @{PDQInventoryServer=<PDQServer>; PDQDeployServer=<PDQServer>} @{PDQInventoryDB=C:\ProgramData\Admin Arsenal\PDQ Deploy\Database.db; PDQDeployDB=C:\ProgramData\Admin Arsenal\PDQ Deploy\Database.db}

         .NOTES
            Author: Caleb Bartle
            Version: 1.1
            Date: 2/6/2021
    #>
        if (!(Test-Path -Path "C:\Program Files\WindowsPowerShell\Modules\PSPDQ\config.json")) {
        Throw "PSPDQ Configuration file not found in `"C:\Program Files\WindowsPowerShell\Modules\PSPDQ\config.json", "please run Set-PSPDQConfig to configure module settings."
    }
    else {
        Get-Content "C:\Program Files\WindowsPowerShell\Modules\PSPDQ\config.json" | ConvertFrom-Json
    }
}
