function Get-PDQScheduleTargets {
    <#
        .SYNOPSIS
            Returns PDQ Schedules

        .DESCRIPTION
            Returns PDQ Schedule Infomration

        .PARAMETER ScheduleName
            Returns all Schedule targets with the specified Schedule Name

        .PARAMETER ScheduleId
            Returns all Schedule targets with the specified Schedule Id

        .EXAMPLE
            Get-PDQScheduleTargets -ScheduleName 'Weekend-ChromeDeployment'
            
            ScheduleId   : 1
            ScheduleName : Weekend-ChromeDeployment
            PackageId    : 1
            PackageName  : Install Chrome
            TriggerType  : Once
            IsEnabled    : 1

            *Get-PDQScheduleTargets Returns all Schedule Targets

        .NOTES
            Author: Caleb Bartle
            Version: 1.1
            Date: 2/6/2021
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $True)]
    param (
        [Parameter(Mandatory = $false,
            ParameterSetName = 'Name')]
        [string[]]$ScheduleName,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'ID')]
        [int[]]$ScheduleId,

        [PSCredential]$Credential
    )

    process {

        Load-PDQConfig

        $Targets = @()

        #Return results only specifying Schedule ID
        if ($PSCmdlet.ParameterSetName -eq 'ID') {
            foreach ($id in $ScheduleId) {
                $sql = "SELECT Schedules.ScheduleId, Schedules.Name, Packages.PackageId, Packages.Name,  Targets.TargetType, Targets.Name
                FROM Targets
                INNER JOIN ScheduleTargets ON ScheduleTargets.TargetId = Targets.TargetId
                INNER JOIN Schedules ON ScheduleTargets.ScheduleId
                INNER JOIN SchedulePackages ON SchedulePackages.ScheduleId = Schedules.ScheduleId
                INNER JOIN Packages ON Packages.PackageId = SchedulePackages.LocalPackageId
                WHERE ScheduleTargets.ScheduleId = $id"

                $icmParams = @{
                    Computer     = $Server
                    ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                    ArgumentList = $sql, $DatabasePath
                }
                if ($Credential) { $icmParams['Credential'] = $Credential }
                $Targets += Invoke-Command @icmParams
            }
            #region obj builder
            $targetsParsed = $Targets | ForEach-Object {
                $p = $_ -split '\|'
                [PSCustomObject]@{
                    ScheduleId   = $p[0]
                    ScheduleName = $p[1]
                    PackageId    = $p[2]
                    PackageName  = $p[3]
                    TargetType   = $p[4]
                    TargetName   = $p[5]
                }
            }

            $targetsParsed.Where({ $_.ScheduleId -eq $ScheduleId })
            #endregion
        }

        #Return results only specifying Schedule Name
        if ($PSCmdlet.ParameterSetName -eq 'Name') {
            foreach ($Name in $ScheduleName) {
                $sql = "SELECT Schedules.ScheduleId, Schedules.Name, Packages.PackageId, Packages.Name,  Targets.TargetType, Targets.Name
            FROM Targets
            INNER JOIN ScheduleTargets ON ScheduleTargets.TargetId = Targets.TargetId
            INNER JOIN Schedules ON ScheduleTargets.ScheduleId
            INNER JOIN SchedulePackages ON SchedulePackages.ScheduleId = Schedules.ScheduleId
            INNER JOIN Packages ON Packages.PackageId = SchedulePackages.LocalPackageId
            WHERE Schedules.Name LIKE '%%$Name%%'"

                $icmParams = @{
                    Computer     = $Server
                    ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                    ArgumentList = $sql, $DatabasePath
                }
                if ($Credential) { $icmParams['Credential'] = $Credential }
                $Targets += Invoke-Command @icmParams
            }
            #region obj builder
            $targetsParsed = $Targets | ForEach-Object {
                $p = $_ -split '\|'
                [PSCustomObject]@{
                    ScheduleId   = $p[0]
                    ScheduleName = $p[1]
                    PackageId    = $p[2]
                    PackageName  = $p[3]
                    TargetType   = $p[4]
                    TargetName   = $p[5]
                }
            }

            $targetsParsed.Where({ $_.ScheduleName -eq $ScheduleName })
            #endregion
        }

        #Loop and return results on all Schedule targets if no parameters specified
        if(($PSCmdlet.ParameterSetName -ne 'Name') -and (($PSCmdlet.ParameterSetName -ne 'ID'))){
            $Schedules = Get-PDQSchedule
            foreach($Sched in $Schedules){
                    $id = $Sched.ScheduleId
                    $sql = "SELECT Schedules.ScheduleId, Schedules.Name, Packages.PackageId, Packages.Name,  Targets.TargetType, Targets.Name
                    FROM Targets
                    INNER JOIN ScheduleTargets ON ScheduleTargets.TargetId = Targets.TargetId
                    INNER JOIN Schedules ON ScheduleTargets.ScheduleId
                    INNER JOIN SchedulePackages ON SchedulePackages.ScheduleId = Schedules.ScheduleId
                    INNER JOIN Packages ON Packages.PackageId = SchedulePackages.LocalPackageId
                    WHERE ScheduleTargets.ScheduleId = $id"

                    $icmParams = @{
                        Computer     = $Server
                        ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
                        ArgumentList = $sql, $DatabasePath
                    }
                    if ($Credential) { $icmParams['Credential'] = $Credential }
                    $Targets += Invoke-Command @icmParams
            }
            #region obj builder
            $targetsParsed = $Targets | ForEach-Object {
                $p = $_ -split '\|'
                [PSCustomObject]@{
                    ScheduleId   = $p[0]
                    ScheduleName = $p[1]
                    PackageId    = $p[2]
                    PackageName  = $p[3]
                    TargetType   = $p[4]
                    TargetName   = $p[5]
                }
            }

            $targetsParsed
            #endregion
        }
    }
}
