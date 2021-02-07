function Get-PDQSchedule {
    <#
        .SYNOPSIS
            Returns PDQ Schedules

        .DESCRIPTION
            Returns PDQ Schedule Infomration

        .PARAMETER ScheduleName
            Returns all Schedules with the specified Schedule Name

        .PARAMETER ScheduleId
            Returns all Schedules with the specified Schedule Id

        .EXAMPLE
            Get-PDQSchedule -ScheduleName 'Weekend-ChromeDeployment'
            
            ScheduleId   : 1
            ScheduleName : Weekend-ChromeDeployment
            PackageId    : 1
            PackageName  : Install Chrome
            TriggerType  : Once
            IsEnabled    : 1

            *Get-PDQSchedule Returns all Schedules

        .NOTES
            Author: Chris Bayliss | Caleb Bartle
            Version: 1.1
            Date: 2/6/2021
    #>

    [CmdletBinding(DefaultParameterSetName = 'Default', SupportsShouldProcess = $True)]
    param (
        # Returns information for computer(s) where the specified user is or has been active
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ScheduleName')]
        [string[]]$ScheduleName,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'ScheduleId')]
        [int[]]$ScheduleId,

        [PSCredential]$Credential
    )
    process {

        Load-PDQConfig

        if ($PSBoundParameters.ContainsKey('Properties')) {
            $defaultProps = "Schedules.ScheduleId", "Schedules.Name", "Packages.PackageId", "Packages.Name", "ScheduleTriggers.TriggerType", "ScheduleTriggers.IsEnabled"
            $allProps = $defaultProps + $Properties
        }
        else {
            $allProps = "Schedules.ScheduleId", "Schedules.Name", "Packages.PackageId", "Packages.Name", "ScheduleTriggers.TriggerType", "ScheduleTriggers.IsEnabled"
        }

        $Schedules = @()

        $sql = "SELECT " + ($allProps -join ', ') + "
                FROM Schedules
                INNER JOIN SchedulePackages ON SchedulePackages.ScheduleId = Schedules.ScheduleId
                INNER JOIN Packages ON Packages.PackageId = SchedulePackages.LocalPackageId
                INNER JOIN ScheduleTriggers ON ScheduleTriggers.ScheduleTriggerSetId = Schedules.ScheduleTriggerSetId"

        $icmParams = @{
            Computer     = $Server
            ScriptBlock  = { $args[0] | sqlite3.exe $args[1] }
            ArgumentList = $sql, $DatabasePath
        }
        if ($Credential) { $icmParams['Credential'] = $Credential }
        $Schedules += Invoke-Command @icmParams
        

        # obj builder
        $schedulesParsed = @()
        $Schedules | ForEach-Object {
            $propsParsed = $_ -split '\|'
            $schedObj = New-Object pscustomobject
            for ($p = 0; $p -lt $allProps.count; $p++) {

                switch ($allProps[$p]) {
                    "Schedules.ScheduleId" { $propName = "ScheduleId" }
                    "Schedules.Name" { $propName = "ScheduleName" }
                    "Packages.PackageId" { $propName = "PackageId" }
                    "Packages.Name" { $propName = "PackageName" }
                    "ScheduleTriggers.TriggerType" { $propName = "TriggerType" }
                    "ScheduleTriggers.IsEnabled" { $propName = "IsEnabled" }
                }

                $schedObj | Add-Member NoteProperty $propName $propsParsed[$p]
            }
            $schedulesParsed += $schedObj
        }

        if (($PSCmdlet.ParameterSetName -ne 'ScheduleName') -and (($PSCmdlet.ParameterSetName -ne 'ScheduleId'))) {
            $schedulesParsed
        }
        if($PSCmdlet.ParameterSetName -eq 'ScheduleName'){
            $schedulesParsed.Where({$_.ScheduleName -eq [string]$ScheduleName })
        }
        if($PSCmdlet.ParameterSetName -eq 'ScheduleId'){
            $schedulesParsed.Where({$_.ScheduleId -eq $ScheduleId })
        }
    }
}