function Get-PDQPackage {
    <#
        .SYNOPSIS
            Get PDQ package information

        .DESCRIPTION
            Retreives PDQ package information for specified package, approved packages or packages awaiting approval

        .PARAMETER PackageID
            ID of PDQ Deploy package to retreive information on

        .PARAMETER PackageName
            Name of PDQ Deploy package to retreive information on

        .PARAMETER Approved
            Returns a list of approved PDQ Deploy packages

        .PARAMETER AwaitingApproval
            Returns a list of PDQ Deploy packages awaiting approval

        .PARAMETER Credential
            Specifies a user account that has permissions to perform this action.

        .EXAMPLE
            Get-PDQPackage -PackageName "Chrome Enterprise 74"

            PackageID   : 6
            PackageName : Google Chrome Enterprise 74.0.3729.131
            Version     : 74.0.3729.131
            Path        : Packages\Google Chrome Enterprise 74.0.3729.131
            Description : Google Chrome Enterprise (with BOTH 32-bit and 64-bit installers)...

            Returns a list of approved PDQ packages matching the string "Chrome Enterprise 74"

        .NOTES
            Author: Chris Bayliss
            Updated By Caleb Bartle
            Version: 1.1
            Date: 2/6/2021
    #>

    [CmdletBinding(SupportsShouldProcess = $True)]
    param (
        [Parameter(Mandatory = $false,
            ParameterSetName = 'ID')]
        [int]$PackageID,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Name')]
        [string]$PackageName,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Approved')]
        [switch]$Approved,

        [Parameter(Mandatory = $false,
            ParameterSetName = 'Waiting')]
        [switch]$AwaitingApproval,

        [PSCredential]$Credential
    )

    process {
        
        Load-PDQConfig

        if ($PSCmdlet.ParameterSetName -eq 'Waiting') {
            $sql = "SELECT Packages.PackageId, Packages.Name, Packages.Version, LibraryPackageVersions.VersionNumber
            FROM Packages
            INNER JOIN LibraryPackageVersions ON Packages.NewLibraryPackageVersionId = LibraryPackageVersions.LibraryPackageVersionId
            WHERE Packages.LibraryPackageVersionId < Packages.NewLibraryPackageVersionId"
        }

        if ($PSCmdlet.ParameterSetName -eq 'Approved') {
            $sql = "SELECT PackageID, Name, Version, Path, REPLACE(REPLACE(Description,CHAR(13),' '),CHAR(10),'')Description FROM Packages"
        }

        if ($PSCmdlet.ParameterSetName -eq 'Name') {
            $sql = "SELECT PackageID, Name, Version, Path, REPLACE(REPLACE(Description,CHAR(13),' '),CHAR(10),'')Description
            FROM Packages
            WHERE Name LIKE '%%$PackageName%%'"
        }

        if ($PSCmdlet.ParameterSetName -eq 'ID') {
            $sql = "SELECT PackageID, Name, Version, Path, REPLACE(REPLACE(Description,CHAR(13),' '),CHAR(10),'')Description
            FROM Packages
            WHERE PackageId = $PackageID"
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
        $packages = Invoke-Command @icmParams

        if ($AwaitingApproval) {
            $packagesParsed = $packages | ForEach-Object {
                $p = $_ -split '\|'
                [PSCustomObject]@{
                    PackageID   = $p[0]
                    PackageName = $p[1]
                    Version     = $p[2]
                    NewVersion  = $p[3]
                }
            }
        }
        else {
            $packagesParsed = $packages | ForEach-Object {
                $p = $_ -split '\|'
                [PSCustomObject]@{
                    PackageID   = $p[0]
                    PackageName = $p[1]
                    Version     = $p[2]
                    Path        = $p[3]
                    Description = $p[4]
                }
            }
        }

        $packagesParsed
    }
}
