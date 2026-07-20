<#
============================================================
Image Distribution Manager Pro
Module : Rename.psm1
Version: 1.0
============================================================
#>

#region Global Variables

$Script:RenameStatistics = [ordered]@{

    TotalFolders     = 0
    TotalFiles       = 0
    RenamedFiles     = 0
    SkippedFiles     = 0
    FailedFiles      = 0

}

#endregion

#############################################################
# Reset Statistics
#############################################################

function Reset-RenameStatistics {

    $Script:RenameStatistics.TotalFolders = 0
    $Script:RenameStatistics.TotalFiles = 0
    $Script:RenameStatistics.RenamedFiles = 0
    $Script:RenameStatistics.SkippedFiles = 0
    $Script:RenameStatistics.FailedFiles = 0

}

#############################################################
# Get Statistics
#############################################################

function Get-RenameStatistics {

    return [PSCustomObject]$Script:RenameStatistics

}

#############################################################
# Get Images
#############################################################

function Get-RenameImages {

    param(
        [string]$Folder
    )

    Get-ChildItem $Folder -File |
    Where-Object{

        $_.Extension.ToLower() -in @(
            ".jpg",
            ".jpeg",
            ".png",
            ".webp"
        )

    } |
    Sort-Object Name

}

#############################################################
# Already Renamed?
#############################################################

function Test-IsAlreadyRenamed {

    param(

        [string]$FolderName,

        $File

    )

    return $File.BaseName.StartsWith($FolderName)

}

#############################################################
# Build New Name
#############################################################

function Get-NewImageName {

    param(

        [string]$FolderName,

        [int]$Index,

        [string]$Extension

    )

    return "{0}_{1}{2}" -f `
        $FolderName,
        $Index,
        $Extension

}

#############################################################
# Rename Folder
#############################################################

function Rename-ImageFolder {

    param(

        [string]$Folder

    )

    $FSN = Split-Path $Folder -Leaf

    $Images = Get-RenameImages $Folder

    $Script:RenameStatistics.TotalFolders++

    $Script:RenameStatistics.TotalFiles += $Images.Count

    $Index = 1

    foreach($Image in $Images){

        if(Test-IsAlreadyRenamed $FSN $Image){

            $Script:RenameStatistics.SkippedFiles++

            $Index++

            continue

        }

        $NewName = Get-NewImageName `
            $FSN `
            $Index `
            $Image.Extension

        try{

            Rename-Item `
                $Image.FullName `
                $NewName `
                -ErrorAction Stop

            $Script:RenameStatistics.RenamedFiles++

            if(Get-Command Write-Log -ErrorAction Ignore){

                Write-Log "Renamed $($Image.Name) -> $NewName"

            }

        }

        catch{

            $Script:RenameStatistics.FailedFiles++

        }

        $Index++

    }

}

#############################################################
# Rename Engine
#############################################################

function Start-RenameEngine {

    param(

        [string]$OutputFolder

    )

    $Folders = Get-ChildItem `
        $OutputFolder `
        -Directory

    $Current = 0

    foreach($Folder in $Folders){

        $Current++

        Write-Progress `
            -Activity "Renaming Images" `
            -Status "$Current / $($Folders.Count)" `
            -PercentComplete (
                ($Current/$Folders.Count)*100
            )

        Rename-ImageFolder `
            $Folder.FullName

    }

    Write-Progress `
        -Activity "Renaming Images" `
        -Completed

}

#############################################################
# Summary
#############################################################

function Show-RenameSummary {

    Write-Host ""

    Write-Host "==================================" `
        -ForegroundColor Cyan

    Write-Host "Rename Summary"

    Write-Host "==================================" `
        -ForegroundColor Cyan

    Get-RenameStatistics |
        Format-List

}

#############################################################
# Export
#############################################################

Export-ModuleMember `
    -Function *
