<#
============================================================
Image Distribution Manager Pro
Module : Verify.psm1
Version : 1.0
============================================================
#>

#region Statistics

$Script:VerifyStats = [ordered]@{

    TotalFolders = 0
    VerifiedFolders = 0

    TotalImages = 0

    EmptyFolders = 0
    InvalidImages = 0
    MissingFolders = 0
    DuplicateFiles = 0

}

#endregion

#############################################################
# Reset Statistics
#############################################################

function Reset-VerifyStatistics{

    $Script:VerifyStats.TotalFolders=0
    $Script:VerifyStats.VerifiedFolders=0
    $Script:VerifyStats.TotalImages=0

    $Script:VerifyStats.EmptyFolders=0
    $Script:VerifyStats.InvalidImages=0
    $Script:VerifyStats.MissingFolders=0
    $Script:VerifyStats.DuplicateFiles=0

}

#############################################################
# Get Statistics
#############################################################

function Get-VerifyStatistics{

    [PSCustomObject]$Script:VerifyStats

}

#############################################################
# Supported Extensions
#############################################################

function Test-ValidExtension{

    param($Extension)

    return $Extension.ToLower() -in @(
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    )

}

#############################################################
# Get Images
#############################################################

function Get-VerifyImages{

    param($Folder)

    Get-ChildItem $Folder -File |
    Where-Object{

        Test-ValidExtension $_.Extension

    }

}
#############################################################
# Verify Folder
#############################################################

function Test-ImageFolder{

    param(

        [string]$Folder

    )

    if(!(Test-Path $Folder)){

        $Script:VerifyStats.MissingFolders++

        return [PSCustomObject]@{

            Folder=$Folder
            Status="Missing"

        }

    }

    $Images=Get-VerifyImages $Folder

    if($Images.Count -eq 0){

        $Script:VerifyStats.EmptyFolders++

    }

    foreach($Image in $Images){

        $Script:VerifyStats.TotalImages++

        if(!(Test-ValidExtension $Image.Extension)){

            $Script:VerifyStats.InvalidImages++

        }

    }

    $Names=$Images.Name

    if(($Names|Sort-Object|Get-Unique).Count -ne $Names.Count){

        $Script:VerifyStats.DuplicateFiles++

    }

    $Script:VerifyStats.VerifiedFolders++

    return [PSCustomObject]@{

        Folder=$Folder
        Images=$Images.Count
        Status="Verified"

    }

}
#############################################################
# Verify Engine
#############################################################

function Start-Verification{

    param(

        [string]$OutputFolder

    )

    $Folders=Get-ChildItem `
        $OutputFolder `
        -Directory

    $Script:VerifyStats.TotalFolders=$Folders.Count

    $Result=@()

    $Current=0

    foreach($Folder in $Folders){

        $Current++

        Write-Progress `
            -Activity "Verifying Images" `
            -Status "$Current / $($Folders.Count)" `
            -PercentComplete (
                ($Current/$Folders.Count)*100
            )

        $Result+=Test-ImageFolder `
            $Folder.FullName

    }

    Write-Progress `
        -Completed `
        -Activity "Verifying"

    return $Result

}

#############################################################
# Summary
#############################################################

function Show-VerifySummary{

    Write-Host ""

    Write-Host "Verification Summary" `
        -ForegroundColor Cyan

    Get-VerifyStatistics |
        Format-List

}

#############################################################
# Export
#############################################################

Export-ModuleMember -Function *
