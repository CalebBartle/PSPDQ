function Set-PDQVariable {
     <#
        .SYNOPSIS
            Sets PDQ Variable information
    
        .DESCRIPTION
            Sets PDQ Custom Variable information
    
        .PARAMETER Name
            Specifies the name of the variable to set for the custom variable.

        .PARAMETER Value
            Specifies the value of the variable to set for the custom variable.

        .EXAMPLE
            Set-PDQVariable -Name "GoogleChromeVersion" -Value '80.1.1.2'
    
            VarNumber   : 2
            VarName     : GoogleChromeVersion
            Value       : 80.1.1.2
            TimeCreated : 2021-02-06 14:15:07
            LastUpdated : 2021-02-06 14:15:29

        .NOTES
            Author: Caleb Bartle
            Version: 1.1
            Date: 2/6/2021
    #>
    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Name')]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )
    PDQDeploy.exe UpdateCustomVariable -Name $Name -Value $Value

    Get-PDQVariable -Name $Name
}