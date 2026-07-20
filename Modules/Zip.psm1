<#
============================================================
Image Distribution Manager Pro
Module : Zip.psm1
Version : 1.0
============================================================
#>

#region Variables

$Script:ZipOutputFolder = ""

#endregion

#############################################################
# Initialize ZIP
#############################################################

function Initialize-Zip {

    param(
        [string]$Folder
    )

    $Script:ZipOutputFolder = $Folder

    if(!(Test-Path $Folder)){

        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null

    }

}

#############################################################
# Create ZIP Filename
#############################################################

function Get-ZipFileName {

    param(
        [string]$Name
    )

    Join-Path `
        $Script:ZipOutputFolder `
        ($Name + ".zip")

}
#############################################################
# Compress One Folder
#############################################################

function Compress-Folder {

    param(

        [string]$Folder

    )

    if(!(Test-Path $Folder)){

        throw "Folder not found."

    }

    $ZipFile = Get-ZipFileName `
        (Split-Path $Folder -Leaf)

    if(Test-Path $ZipFile){

        Remove-Item `
            $ZipFile `
            -Force

    }

    Compress-Archive `
        -Path "$Folder\*" `
        -DestinationPath $ZipFile `
        -CompressionLevel Optimal

    if(Get-Command Write-Log -ErrorAction Ignore){

        Write-Log "ZIP Created : $ZipFile"

    }

    return $ZipFile

}

#############################################################
# Compress Multiple Folders
#############################################################

function Compress-Folders {

    param(

        [string[]]$Folders

    )

    $Result = @()

    foreach($Folder in $Folders){

        $Result += Compress-Folder $Folder

    }

    return $Result

}
#############################################################
# Compress Entire Output
#############################################################

function Compress-Output {

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
            -Activity "Creating ZIP Files" `
            -Status "$Current / $($Folders.Count)" `
            -PercentComplete (
                ($Current/$Folders.Count)*100
            )

        Compress-Folder `
            $Folder.FullName | Out-Null

    }

    Write-Progress `
        -Activity "Creating ZIP Files" `
        -Completed

}

#############################################################
# Compress Everything Into One ZIP
#############################################################

function Compress-Project {

    param(

        [string]$OutputFolder,

        [string]$ProjectName = "Project"

    )

    $Zip = Get-ZipFileName $ProjectName

    if(Test-Path $Zip){

        Remove-Item `
            $Zip `
            -Force

    }

    Compress-Archive `
        -Path "$OutputFolder\*" `
        -DestinationPath $Zip `
        -CompressionLevel Optimal

    return $Zip

}

#############################################################
# Export Module
#############################################################

Export-ModuleMember `
-Function `
Initialize-Zip,
Compress-Folder,
Compress-Folders,
Compress-Output,
Compress-Project
