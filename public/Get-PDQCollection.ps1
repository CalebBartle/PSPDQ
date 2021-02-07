function Get-PDQCollection {
    <#
    .SYNOPSIS
        Returns information on PDQ Inventory collections

    .DESCRIPTION
        Returns information on either all or specified PDQ Inventory collections

    .PARAMETER Credential
        Specifies a user account that has permissions to perform this action.

    .EXAMPLE
        Get-PDQCollection -CollectionName "Online"
        Returns information on all collections matching the string "Online"

    .NOTES
        Author: Chris Bayliss
        Updated By Caleb Bartle
        Version: 1.1
        Date: 2/6/2021
    #>

    [CmdletBinding()]
    param (
        # Collection name to query
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ColName')]
        [string[]]$CollectionName,

        #Collection ID number to query
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ColID')]
        [int[]]$CollectionID,

        # Returns information on all collections
        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [switch]$All,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Path', 'IsDrillDown', 'Created', 'Modified', 'ParentId', 'Type', 'Description', 'IsEnabled')]
        [string[]]$Properties,

        [PSCredential]$Credential
    )

    process {

        Load-PDQConfig

        if ($PSBoundParameters.ContainsKey($Properties)) {
            $defaultProps = 'CollectionId', 'Name', 'Type', 'ComputerCount'
            $allProps = $defaultProps + $Properties
        }
        else {
            $allProps = 'CollectionId', 'Name', 'Type', 'ComputerCount'
        }

        if ($PSCmdlet.ParameterSetName -eq 'ColName') {
            $Collections = @()

            foreach ($col in $CollectionName) {
                $sql = "SELECT " + ($allProps -join ', ') + "
                        FROM Collections
                        WHERE Name LIKE '%%$col%%'"

                $icmParams = @{
                    Computer     = $Server
                    ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                    ArgumentList = $sql, $DatabasePath
                }
                if ($Credential) { $icmParams['Credential'] = $Credential }

                $Collections += Invoke-Command @icmParams
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'ColID') {
            $Collections = @()

            foreach ($i in $CollectionID) {
                $sql = "SELECT " + ($allProps -join ', ') + "
                        FROM Collections
                        WHERE CollectionId = $i"

                $icmParams = @{
                    Computer     = $Server
                    ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                    ArgumentList = $sql, $DatabasePath
                }
                if ($Credential) { $icmParams['Credential'] = $Credential }

                $Collections += Invoke-Command @icmParams
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $sql = "SELECT " + ($allProps -join ', ') + "
            FROM Collections"

            $icmParams = @{
                Computer     = $Server
                ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                ArgumentList = $sql, $DatabasePath
            }
            if ($Credential) { $icmParams['Credential'] = $Credential }
            $Collections = Invoke-Command @icmParams
        }

        $collectionsParsed = @()
        $Collections | ForEach-Object {
            $propsParsed = $_ -split '\|'
            $colObj = New-Object pscustomobject
            for ($p = 0; $p -lt $allProps.count; $p++) {
                $colObj | Add-Member NoteProperty $allProps[$p] $propsParsed[$p]
            }
            $collectionsParsed += $colObj
        }

        $collectionsParsed
    }
}
