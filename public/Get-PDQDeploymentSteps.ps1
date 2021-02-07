function Get-PDQDeploymentSteps {
    <#
        .SYNOPSIS
            Returns deployment steps and their results

        .DESCRIPTION
            Returns deployment steps and their results for the specified deployment ID or all deployment ste

        .PARAMETER DeploymentId
            Specifies deployment ID to return steps for

        .PARAMETER Computer
            Specifies computer to return steps for (CASE SENSITIVE)

        .PARAMETER Credential
            Specifies a user account that has permissions to perform this action.

        .EXAMPLE
            Get-PDQDeployment -Computer WK01 | ? PackageName -like "*Chrome*" | Get-PDQDeploymentSteps

            Returns all deployment steps for any Chrome packages deployed to WK01

        .NOTES
            Author: Chris Bayliss
            Updated By Caleb Bartle
            Version: 1.1
            Date: 2/6/2021
    #>

    [CmdletBinding(SupportsShouldProcess = $True, DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory = $true,
            ParameterSetName = 'Default',
            ValueFromPipelineByPropertyName)]
        [int[]]$DeploymentId,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Default',
            ValueFromPipelineByPropertyName)]
        [string[]][alias('Name')]$Computer,

        [PSCredential]$Credential
    )

    process {

        Load-PDQConfig

        $Steps = @()

        foreach ($id in $DeploymentId) {
            $sql = "SELECT Deployments.DeploymentId, Deployments.PackageId, DeploymentComputers.ShortName, Deployments.PackageName, Deployments.PackageVersion, Deployments.Status,
                    DeploymentComputerSteps.DeploymentComputerStepId, DeploymentComputerSteps.Number, DeploymentComputerSteps.Title, DeploymentComputerSteps.ReturnCode, DeploymentComputerSteps.Started,
                    DeploymentComputerSteps.Finished, REPLACE(REPLACE(DeploymentComputers.Error,CHAR(13), ' '),CHAR(10),''), DeploymentComputerSteps.IsFailed, DeploymentComputerSteps.Note
                    FROM Deployments
                    INNER JOIN DeploymentComputers ON Deployments.DeploymentId = DeploymentComputers.DeploymentId
                    INNER JOIN DeploymentComputerSteps ON DeploymentComputers.DeploymentComputerId = DeploymentComputerSteps.DeploymentComputerId
                    WHERE DeploymentComputers.DeploymentId = $id"
            if ($Computer) {
                $sql += " AND DeploymentComputers.ShortName IN ('$Computer')"
            }

            $icmParams = @{
                Computer     = $Server
                ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                ArgumentList = $sql, $DatabasePath
            }
            if ($Credential) { $icmParams['Credential'] = $Credential }
            $Steps += Invoke-Command @icmParams
        }

        $stepsParsed = $Steps | ForEach-Object {
            $p = $_ -split '\|'
            if ($p[12]) {
                $p[12] -match '<Message>.*</Message>' | Out-Null
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
                JobState     = $p[5]
                StepID       = $p[6]
                StepNumber   = $p[7]
                StepTitle    = $p[8]
                ReturnCode   = $p[9]
                StepStart    = $p[10]
                StepFinish   = $p[11]
                Error        = $p[12]
                Failed       = if ($p[13] -eq '1') { "Yes" } else { "No" }
                Note         = $p[14]
            }
        }

        $stepsParsed
    }
}
