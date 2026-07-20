<#
============================================================
Image Distribution Manager Pro
Module : Backup.psm1
Version : 1.0
============================================================
#>

#region Variables

$Script:BackupRoot = ""
$Script:CurrentBackup = ""

#endregion

#############################################################
# Initialize Backup
#############################################################

function Initialize-Backup {

    param(

        [string]$Folder

    )

    $Script:BackupRoot = $Folder

    if(!(Test-Path $Folder)){

        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null

    }

}

#############################################################
# Create Backup Folder
#############################################################

function New-BackupFolder {

    $TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

    $Script:CurrentBackup = Join-Path `
        $Script:BackupRoot `
        $TimeStamp

    New-Item `
        -ItemType Directory `
        -Path $Script:CurrentBackup `
        -Force | Out-Null

    return $Script:CurrentBackup

}
#############################################################
# Backup Folder
#############################################################

function Backup-Folder {

    param(

        [string]$SourceFolder

    )

    if(!(Test-Path $SourceFolder)){

        return $null

    }

    if([string]::IsNullOrWhiteSpace($Script:CurrentBackup)){

        New-BackupFolder | Out-Null

    }

    $Destination = Join-Path `
        $Script:CurrentBackup `
        (Split-Path $SourceFolder -Leaf)

    Copy-Item `
        $SourceFolder `
        -Destination $Destination `
        -Recurse `
        -Force

    if(Get-Command Write-Log -ErrorAction Ignore){

        Write-Log "Backup created : $Destination"

    }

    return $Destination

}

#############################################################
# Backup Multiple Folders
#############################################################

function Backup-Folders {

    param(

        [string[]]$Folders

    )

    foreach($Folder in $Folders){

        Backup-Folder `
            $Folder | Out-Null

    }

}
#############################################################
# Restore Backup
#############################################################

function Restore-Backup {

    param(

        [string]$BackupFolder,

        [string]$Destination

    )

    if(!(Test-Path $BackupFolder)){

        throw "Backup folder not found."

    }

    Copy-Item `
        "$BackupFolder\*" `
        -Destination $Destination `
        -Recurse `
        -Force

    if(Get-Command Write-Log -ErrorAction Ignore){

        Write-Log "Backup restored from $BackupFolder"

    }

}

#############################################################
# List Backups
#############################################################

function Get-Backups {

    if(!(Test-Path $Script:BackupRoot)){

        return @()

    }

    Get-ChildItem `
        $Script:BackupRoot `
        -Directory |
    Sort-Object Name -Descending

}

#############################################################
# Remove Old Backups
#############################################################

function Remove-OldBackups {

    param(

        [int]$KeepLast = 10

    )

    $Backups = Get-Backups

    if($Backups.Count -le $KeepLast){

        return

    }

    $Backups |

        Select-Object -Skip $KeepLast |

        Remove-Item `
        -Recurse `
        -Force

}

#############################################################
# Export Module
#############################################################

Export-ModuleMember `
-Function `
Initialize-Backup,
New-BackupFolder,
Backup-Folder,
Backup-Folders,
Restore-Backup,
Get-Backups,
Remove-OldBackups
