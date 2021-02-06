function Get-PDQVariable {
 <#
    .SYNOPSIS
        Get PDQ Variable information
    
    .DESCRIPTION
        Retreives PDQ Custom Variable information and stores into a PS Table
    
    .PARAMETER Name
        Specifies the name of the variable to search the DB for.

    .PARAMETER Credential
        Specifies a user account that has permissions to perform this action.

    .EXAMPLE
        Get-PDQVariable -Name "GoogleChromeVersion"
    
        VarNumber   : 2
        VarName     : GoogleChromeVersion
        Value       : 80.1.1.2
        TimeCreated : 2021-02-06 14:15:07
        LastUpdated : 2021-02-06 14:15:29

        Using Get-PDQVariable will list all available Custom Variables in the PDQ database

    .NOTES
        Author: Caleb Bartle
#>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Name')]
        [string]$Name,

        [PSCredential]$Credential
    )

    process {
        if (!(Test-Path -Path "$($env:AppData)\pspdq\config.json")) {
            Throw "PSPDQ Configuration file not found in `"$($env:AppData)\pspdq\config.json`", please run Set-PSPDQConfig to configure module settings."
        }
        else {
            $config = Get-Content "$($env:AppData)\pspdq\config.json" | ConvertFrom-Json

            $Server = $config.Server.PDQDeployServer
            $DatabasePath = $config.DBPath.PDQDeployDB
        }

        if ($PSCmdlet.ParameterSetName -eq 'Name') {
            $sql = "SELECT *
            FROM CustomVariables
            WHERE Name LIKE '%%$Name%%'"
        }

        if ($PSCmdlet.ParameterSetName -ne 'Name') {
            $sql = "SELECT *
            FROM CustomVariables;"
        }

        if (!(Test-Path -Path "\\$($Server)\c$\ProgramData\Admin Arsenal\PDQ Deploy\Database.db")) {
            Write-Error -Message "Unable to locate database. Ensure you have access and the path entered is correct."
        }

        $icmParams = @{
            Computer     = $Server
            ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
            ArgumentList = $sql, $DatabasePath
        }

        if ($Credential) { $icmParams['Credential'] = $Credential }
        $Variables = Invoke-Command @icmParams

        $VarList = $Variables | ForEach-Object {
            $v = $_ -split '\|'
            [PSCustomObject]@{
                VarNumber   = $v[0]
                VarName     = $v[1]
                Value       = $v[2]
                TimeCreated = $v[3]
                LastUpdated = $v[4]
            }
        }

        $VarList
    }
}