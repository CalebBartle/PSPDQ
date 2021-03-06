function Get-PDQHotFixes {
    <#
        .SYNOPSIS
            Get information on hotfix/patches installed on specified target

        .DESCRIPTION
            Retreives information on all hotfixes/patches installed on the target systems which have been scanned by PDQ Inventory.

        .PARAMETER Computer
            Target computer to return hotfix/patch information for

        .PARAMETER HotFix
            Specified hotfix/patch to return information for

        .PARAMETER Credential
            Specifies a user account that has permissions to perform this action.


        .EXAMPLE
            Get-PDQHotFixes -Computer WK01

            Returns all patches installed on WK01

        .EXAMPLE
            Get-PDQHotFixes -HotFix KB000001

            Returns a list of machines which have patch "KB00001" installed

        .NOTES
            Author: Chris Bayliss
            Updated By Caleb Bartle
            Version: 1.1
            Date: 2/6/2021
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Comp',
            ValueFromPipelineByPropertyName,
            Position = 0)]
        [string][alias('Name')]$Computer,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'HF',
            ValueFromPipelineByPropertyName)]
        [string]$HotFix,

        [PSCredential]$Credential
    )

    process {
        
        Load-PDQConfig

        if ($PSCmdlet.ParameterSetName -eq 'Comp') {
            $sql = "SELECT hotfixes.hotfixid, hotfixes.computerid, computers.name, hotfixes.name, hotfixes.Description, hotfixes.InstalledOn, hotfixes.InstalledBy, hotfixes.Program, hotfixes.Version, hotfixes.Publisher, hotfixes.HelpLink
            FROM HotFixes
            INNER JOIN Computers on hotfixes.ComputerId = computers.ComputerId
            WHERE Computers.Name LIKE '%%$Computer%%'
            ORDER BY hotfixes.InstalledOn DESC"
        }

        if ($PSCmdlet.ParameterSetName -eq 'HF') {
            $sql = "SELECT hotfixes.hotfixid, hotfixes.computerid, computers.name, hotfixes.name, hotfixes.Description, hotfixes.InstalledOn, hotfixes.InstalledBy, hotfixes.Program, hotfixes.Version, hotfixes.Publisher, hotfixes.HelpLink
            FROM HotFixes
            INNER JOIN Computers on hotfixes.ComputerId = computers.ComputerId
            WHERE Hotfixes.Name LIKE '%%$HotFix%%'
            ORDER BY hotfixes.InstalledOn DESC"
        }

        $icmParams = @{
            Computer     = $Server
            ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
            ArgumentList = $sql, $DatabasePath
        }
        if ($Credential) { $icmParams['Credential'] = $Credential }
        $HotFixes = Invoke-Command @icmParams

        $HotFixesParsed = $HotFixes | ForEach-Object {
            $p = $_ -split '\|'
            [PSCustomObject]@{
                HotFixID    = $p[0]
                ComputerID  = $p[1]
                Computer    = $p[2]
                Name        = $p[3]
                Description = $p[4]
                InstalledOn = $p[5]
                InstalledBy = $p[6]
                Program     = $p[7]
                Version     = $p[8]
                Publisher   = $p[9]
                HelpLink    = $p[10]
            }
        }

        $HotFixesParsed
    }
}
