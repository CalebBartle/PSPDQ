function Get-PDQDeployment {
    <#
    .SYNOPSIS
        Get details on PDQ Deploy deployment

    .DESCRIPTION
        Retreives details on PDQ Deploy deployments for the specified computer, deployment id, or package
    .PARAMETER Credential
        Specifies a user account that has permissions to perform this action.

    .EXAMPLE
        Get-PDQDeployment -PackageID 1
        Returns deployment data for the package with the ID of 1

    .EXAMPLE
        Get-PDQPackage -PackageName "7-Zip" | Get-PDQDeployment
        Returns deployment data for applications containing "7-Zip" in the name

    .NOTES
        Author: Chris Bayliss
        Updated By Caleb Bartle
        Version: 1.1
        Date: 2/6/2021
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        # Will return all deployment data related to target
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Comp',
            ValueFromPipelineByPropertyName)]
        [string[]][alias('Name')]$Computer,

        # Returns deployment data for specified package
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Name',
            ValueFromPipelineByPropertyName)]
        [string]$PackageName,

        # Returns deployment data for specified package
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ID',
            ValueFromPipelineByPropertyName)]
        [int]$PackageID,

        # Returns deployment data for specified deployment id
        [Parameter(Mandatory = $false,
            ParameterSetName = 'DepID',
            ValueFromPipelineByPropertyName)]
        [int]$DeploymentID,

        # Returns most recent deployment information for up to the entered number
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Recent')]
        [int]$Recent = 10,

        [PSCredential]$Credential
    )

    process {

        Load-PDQConfig

        $Deployments = @()

        if ($PSCmdlet.ParameterSetName -eq 'Comp') {
            foreach ($Comp in $Computer) {
                $sql = "SELECT Deployments.DeploymentId, Deployments.PackageId, DeploymentComputers.ShortName, Deployments.PackageName, Deployments.PackageVersion, Deployments.Started, Deployments.Finished, DeploymentComputers.Status, REPLACE(REPLACE(DeploymentComputers.Error,CHAR(13), ' '),CHAR(10),'')
                FROM Deployments
                INNER JOIN DeploymentComputers ON Deployments.DeploymentId = DeploymentComputers.DeploymentId
                WHERE Deployments.DeploymentId IN (
                SELECT DeploymentId
                FROM DeploymentComputers
                WHERE ShortName LIKE '%%$Comp%%')
                AND DeploymentComputers.ShortName LIKE '%%$Comp%%'
                ORDER BY Deployments.Finished DESC"

                $icmParams = @{
                    Computer     = $Server
                    ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                    ArgumentList = $sql, $DatabasePath
                }
                if ($Credential) { $icmParams['Credential'] = $Credential }
                $Deployments += Invoke-Command @icmParams
            }
        }

        if ($PSCmdlet.ParameterSetName -eq 'Name') {
            $sql = "SELECT Deployments.DeploymentId, Deployments.PackageId, DeploymentComputers.ShortName, Deployments.PackageName, Deployments.PackageVersion, Deployments.Started, Deployments.Finished, DeploymentComputers.Status, REPLACE(REPLACE(DeploymentComputers.Error,CHAR(13), ' '),CHAR(10),'')
            FROM Deployments
            INNER JOIN DeploymentComputers ON Deployments.DeploymentId = DeploymentComputers.DeploymentId
            WHERE Deployments.PackageName LIKE '%%$PackageName%%'
            ORDER BY Deployments.Finished DESC"
        }

        if ($PSCmdlet.ParameterSetName -eq 'ID') {
            $sql = "SELECT Deployments.DeploymentId, Deployments.PackageId, DeploymentComputers.ShortName, Deployments.PackageName, Deployments.PackageVersion, Deployments.Started, Deployments.Finished, DeploymentComputers.Status, REPLACE(REPLACE(DeploymentComputers.Error,CHAR(13), ' '),CHAR(10),'')
            FROM Deployments
            INNER JOIN DeploymentComputers ON Deployments.DeploymentId = DeploymentComputers.DeploymentId
            WHERE Deployments.PackageId = $PackageID
            ORDER BY Deployments.Finished DESC"
        }

        if ($PSCmdlet.ParameterSetName -eq 'DepID') {
            $sql = "SELECT Deployments.DeploymentId, Deployments.PackageId, DeploymentComputers.ShortName, Deployments.PackageName, Deployments.PackageVersion, Deployments.Started, Deployments.Finished, DeploymentComputers.Status, REPLACE(REPLACE(DeploymentComputers.Error,CHAR(13), ' '),CHAR(10),'')
            FROM Deployments
            INNER JOIN DeploymentComputers ON Deployments.DeploymentId = DeploymentComputers.DeploymentId
            WHERE Deployments.DeploymentId = $DeploymentID
            ORDER BY Deployments.Finished DESC"
        }

        if ($PSCmdlet.ParameterSetName -eq 'Recent') {
            $sql = "SELECT Deployments.DeploymentId, Deployments.PackageId, DeploymentComputers.ShortName, Deployments.PackageName, Deployments.PackageVersion, Deployments.Started, Deployments.Finished, DeploymentComputers.Status, REPLACE(REPLACE(DeploymentComputers.Error,CHAR(13), ' '),CHAR(10),'')
            FROM Deployments
            INNER JOIN DeploymentComputers ON Deployments.DeploymentId = DeploymentComputers.DeploymentId
            ORDER BY Deployments.Finished DESC
            LIMIT $Recent"
        }

        if ($PSCmdlet.ParameterSetName -ne 'Comp') {

            $icmParams = @{
                Computer     = $Server
                ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                ArgumentList = $sql, $DatabasePath
            }
            if ($Credential) { $icmParams['Credential'] = $Credential }
            $Deployments = Invoke-Command @icmParams
        }

        $DeploymentsParsed = $Deployments | ForEach-Object {
            $p = $_ -split '\|'
            if ($p[8]) {
                $p[8] -match '<Message>.*</Message>' | Out-Null
                $msg = ($Matches.Values | Out-String).Replace('<Message>', '').Replace('</Message>', '')
            }
            else {
                $msg = $null
            }
            [PSCustomObject]@{
                DeploymentID = $p[0]
                PackageID    = $p[1]
                Computer     = $p[2]
                PackageName  = $p[3]
                Version      = $p[4]
                JobStart     = $p[5]
                JobFinish    = $p[6]
                JobState     = $p[7]
                JobMessage   = $msg
            }
        }

        $DeploymentsParsed
    }
}