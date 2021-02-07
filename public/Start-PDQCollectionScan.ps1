function Start-PDQCollectionScan {
    <#
        .SYNOPSIS
            Scan target collection with specified scan profile.

        .DESCRIPTION
            Scan the target collection with the scan profile specified. By default the "Standard" profile will be used.
            Requires PDQ Inventory client or server to be installed locally.

        .PARAMETER Collection
            Name of collection to scan

        .PARAMETER ScanProfile
            Profile to scan the target computer with

        .PARAMETER Credential
            Specifies a user account that has permissions to perform this action.

        .EXAMPLE
            Start-PDQCollectionScan -Collection "Online Systems" -ScanProfile "Standard"
            Scan the target collection "Online Systems" with the "Standard" scan profile

        .NOTES
            Author: Chris Bayliss | Caleb Bartle
            Updated By Caleb Bartle
            Version: 1.1
            Date: 2/6/2021
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true,
            Position = 0,
            ValueFromPipelinebyPropertyName)]
        [Alias('Name')]
        [string[]]$Collection,

        [Parameter(Position = 1)]
        [string]$ScanProfile = "Standard",

        [PSCredential]$Credential
    )
    process {
        Load-PDQConfig

        $icmParams = @{
            Computer     = $Server
            ScriptBlock  = { PDQInventory.exe ScanCollections -ScanProfile $using:ScanProfile -Collections $using:Collection }
            ArgumentList = $ScanProfile, $Collection
        }
        if ($Credential) { $icmParams['Credential'] = $Credential }
        Invoke-Command @icmParams
    }
}

