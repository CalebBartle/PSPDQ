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
            Version: 1.1
            Date: 2/6/2021
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Name')]
        [string]$Name,

        [PSCredential]$Credential
    )

    process {
        
        Load-PDQConfig

        if ($PSCmdlet.ParameterSetName -eq 'Name') {
            $sql = "SELECT *
            FROM CustomVariables
            WHERE Name LIKE '%%$Name%%'"
        }

        if ($PSCmdlet.ParameterSetName -ne 'Name') {
            $sql = "SELECT *
            FROM CustomVariables;"
        }

        if (!(Test-Path -Path $config.DBPath.PDQDeployDB)) {
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