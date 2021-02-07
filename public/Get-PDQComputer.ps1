function Get-PDQComputer {
    <#
    .SYNOPSIS
        Returns info for computer held within PDQ Inventory

    .DESCRIPTION
        Returns info for computer held within PDQ Inventory

    .PARAMETER All
        Switch. Will pull all results from PDQ Inventory.

    .PARAMETER Computer
        Defines computer(s) to return results for.

    .PARAMETER User
        If specified, results will only contain computers which the user is accessing.

    .PARAMETER Properties
        Specifies properties to include in results.

    .PARAMETER Credential
        Specifies a user account that has permissions to perform this action.

    .EXAMPLE
        Get-PDQComputer -Computer WK01
        Returns PDQ Inventory information for WK01

    .NOTES
        Author: Chris Bayliss
        Updated By Caleb Bartle
        Version: 1.1
        Date: 2/6/2021
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $True)]
    param (
        # Returns all information
        [Parameter(Mandatory = $false,
            ParameterSetName = 'All')]
        [switch]$All,

        # Returns information for specified computer
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Computer',
            ValueFromPipelineByPropertyName,
            Position = 0)]
        [string[]][alias('Name')]$Computer,

        # Returns information for computer(s) where the specified user is or has been active
        [Parameter(Mandatory = $false,
            ParameterSetName = 'User')]
        [string[]]$User,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Added', 'BootTime', 'Manufacturer', 'Memory', 'SerialNumber', 'OSArchitecture',
            'IPAddress', 'CurrentUser', 'MacAddress', 'DotNetVersions', 'NeedsReboot', 'PSVersion', 'ADLogonServer',
            'SMBv1Enabled', 'SimpleReasonForReboot', 'IsOnline', 'OSVersion', 'OSSerialNumber', 'SystemDrive',
            'IEVersion', 'HeartbeatDate', 'ADDisplayName', 'BiosVersion', 'BiosManufacturer', 'Chassis', 'ADLogonServer',
            'AddedFrom', 'ADIsDisabled')]
        [string[]]$Properties,

        [PSCredential]$Credential
    )

    process {

        Load-PDQConfig

        if ($PSBoundParameters.ContainsKey('Properties')) {
            $defaultProps = "ComputerId", "Name", "Model", "OSName", "OSServicePack"
            $allProps = $defaultProps + $Properties
        }
        else {
            $allProps = "ComputerId", "Name", "Model", "OSName", "OSServicePack"
        }

        $Computers = @()

        if ($PSCmdlet.ParameterSetName -eq 'All') {
            $sql = "SELECT " + ($allProps -join ', ') + "
            FROM Computers"

            $icmParams = @{
                Computer     = $Server
                ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                ArgumentList = $sql, $DatabasePath
            }
            if ($Credential) { $icmParams['Credential'] = $Credential }
            $Computers += Invoke-Command @icmParams
        }

        if ($PSCmdlet.ParameterSetName -eq 'Computer') {
            foreach ($Comp in $Computer) {
                $sql = "SELECT " + ($allProps -join ', ') + "
                FROM Computers
                WHERE Name LIKE '%%$Comp%%'"

                $icmParams = @{
                    Computer     = $Server
                    ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                    ArgumentList = $sql, $DatabasePath
                }
                if ($Credential) { $icmParams['Credential'] = $Credential }
                $Computers += Invoke-Command @icmParams
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'User') {
            foreach ($u in $user) {
                $sql = "SELECT " + ($allProps -join ', ') + "
                FROM Computers
                WHERE CurrentUser LIKE '%%$u%%'"

                $icmParams = @{
                    Computer     = $Server
                    ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                    ArgumentList = $sql, $DatabasePath
                }
                if ($Credential) { $icmParams['Credential'] = $Credential }
                $Computers += Invoke-Command @icmParams
            }
        }

        # obj builder
        $computersParsed = @()
        $Computers | ForEach-Object {
            $propsParsed = $_ -split '\|'
            $compObj = New-Object pscustomobject
            for ($p = 0; $p -lt $allProps.count; $p++) {
                $compObj | Add-Member NoteProperty $allProps[$p] $propsParsed[$p]
            }
            $computersParsed += $compObj
        }

        $computersParsed
    }
}
