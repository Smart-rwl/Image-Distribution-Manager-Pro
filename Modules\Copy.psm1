<#
============================================================
Image Distribution Manager Pro
Module : Copy.psm1
Version: 1.0
Author : Ravinder Rawal + ChatGPT

Purpose:
    High performance image copy engine.

============================================================
#>

#region Global Variables

$Script:SupportedExtensions = @(
    ".jpg",
    ".jpeg",
    ".png",
    ".webp"
)

$Script:CopyStatistics = [ordered]@{

    TotalFolders = 0
    ProcessedFolders = 0

    TotalImages = 0
    CopiedImages = 0

    SkippedImages = 0
    FailedImages = 0

    MissingModels = 0

}

#endregion

#############################################################
# Reset Statistics
#############################################################

function Reset-CopyStatistics {

    $Script:CopyStatistics.TotalFolders = 0
    $Script:CopyStatistics.ProcessedFolders = 0

    $Script:CopyStatistics.TotalImages = 0
    $Script:CopyStatistics.CopiedImages = 0

    $Script:CopyStatistics.SkippedImages = 0
    $Script:CopyStatistics.FailedImages = 0

    $Script:CopyStatistics.MissingModels = 0

}

#############################################################
# Return Statistics
#############################################################

function Get-CopyStatistics {

    return [PSCustomObject]$Script:CopyStatistics

}

#############################################################
# Extension Validation
#############################################################

function Test-ImageExtension {

    param(

        [string]$Extension

    )

    return $Script:SupportedExtensions.Contains(
        $Extension.ToLower()
    )

}

#############################################################
# Validate Folder
#############################################################

function Test-SourceFolder {

    param(

        [string]$Path

    )

    if([string]::IsNullOrWhiteSpace($Path)){

        return $false

    }

    return (Test-Path $Path)

}

#############################################################
# Create Folder
#############################################################

function New-OutputFolder {

    param(

        [string]$Path

    )

    if(!(Test-Path $Path)){

        New-Item `
            -ItemType Directory `
            -Path $Path `
            -Force | Out-Null

    }

}

#############################################################
# Get Image Files
#############################################################

function Get-ImageFiles {

    param(

        [string]$Folder

    )

    if(!(Test-Path $Folder)){

        return @()

    }

    Get-ChildItem `
        -Path $Folder `
        -File |

    Where-Object{

        Test-ImageExtension $_.Extension

    }

}

#############################################################
# Validate Mapping Row
#############################################################

function Test-MappingRow {

    param(

        $Row

    )

    if($null -eq $Row){

        return $false

    }

    if([string]::IsNullOrWhiteSpace($Row.model)){

        return $false

    }

    if([string]::IsNullOrWhiteSpace($Row.FSN)){

        return $false

    }

    return $true

}

#############################################################
# Build Queue
#############################################################

function New-CopyQueue {

    param(

        [array]$Mappings,

        [string]$SourceRoot,

        [string]$OutputRoot

    )

    $Queue = @()

    foreach($Row in $Mappings){

        if(!(Test-MappingRow $Row)){

            continue

        }

        $Queue += [PSCustomObject]@{

            Model = $Row.model.Trim()

            FSN = $Row.FSN.Trim()

            SourceFolder = Join-Path `
                $SourceRoot `
                $Row.model.Trim()

            DestinationFolder = Join-Path `
                $OutputRoot `
                $Row.FSN.Trim()

            Status = "Pending"

            Images = 0

            Started = $null

            Finished = $null

        }

    }

    $Script:CopyStatistics.TotalFolders = $Queue.Count

    return $Queue

}

#############################################################
# Preview Queue
#############################################################

function Show-CopyPreview {

    param(

        [array]$Queue

    )

    Clear-Host

    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "             COPY PREVIEW"
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host ("Folders : " + $Queue.Count)

    $ImageCount = 0

    foreach($Item in $Queue){

        if(Test-Path $Item.SourceFolder){

            $ImageCount += (
                Get-ImageFiles $Item.SourceFolder
            ).Count

        }

    }

    Write-Host ("Images  : " + $ImageCount)

    Write-Host ""

    $Script:CopyStatistics.TotalImages = $ImageCount

}

#############################################################
# Validate Queue
#############################################################

function Test-CopyQueue {

    param(

        [array]$Queue

    )

    foreach($Item in $Queue){

        if(!(Test-Path $Item.SourceFolder)){

            $Item.Status = "Missing Model"

            $Script:CopyStatistics.MissingModels++

        }

    }

    return $Queue

}

#############################################################
# Invoke Robocopy
#############################################################

function Invoke-RobocopyCopy {

    param(

        [string]$Source,

        [string]$Destination,

        [switch]$DryRun

    )

    New-OutputFolder $Destination

    if($DryRun){

        return $true

    }

    $Arguments = @(
        "`"$Source`"",
        "`"$Destination`"",
        "*.jpg",
        "*.jpeg",
        "*.png",
        "*.webp",
        "/R:3",
        "/W:1",
        "/NFL",
        "/NDL",
        "/NJH",
        "/NJS",
        "/NC",
        "/NS"
    )

    $Process = Start-Process `
        -FilePath robocopy.exe `
        -ArgumentList $Arguments `
        -Wait `
        -NoNewWindow `
        -PassThru

    if($Process.ExitCode -le 7){

        return $true

    }

    return $false

}

#############################################################
# Copy Using Copy-Item
#############################################################

function Invoke-CopyItemCopy {

    param(

        [string]$Source,

        [string]$Destination,

        [switch]$DryRun

    )

    New-OutputFolder $Destination

    $Files = Get-ImageFiles $Source

    foreach($File in $Files){

        if($DryRun){

            continue

        }

        try{

            Copy-Item `
                $File.FullName `
                -Destination $Destination `
                -Force `
                -ErrorAction Stop

            $Script:CopyStatistics.CopiedImages++

        }

        catch{

            $Script:CopyStatistics.FailedImages++

        }

    }

}

#############################################################
# Retry Copy
#############################################################

function Invoke-RetryCopy {

    param(

        [string]$Source,

        [string]$Destination,

        [int]$Retries = 3,

        [switch]$DryRun

    )

    $Attempt = 1

    while($Attempt -le $Retries){

        $Success = Invoke-RobocopyCopy `
            -Source $Source `
            -Destination $Destination `
            -DryRun:$DryRun

        if($Success){

            return $true

        }

        Write-Host ""

        Write-Host "Retry $Attempt of $Retries" `
            -ForegroundColor Yellow

        Start-Sleep 1

        $Attempt++

    }

    Write-Host ""

    Write-Host "Robocopy Failed." `
        -ForegroundColor Yellow

    Write-Host "Using Copy-Item..." `
        -ForegroundColor Yellow

    Invoke-CopyItemCopy `
        -Source $Source `
        -Destination $Destination `
        -DryRun:$DryRun

    return $true

}

#############################################################
# Process One Queue Item
#############################################################

function Invoke-CopyQueueItem {

    param(

        $QueueItem,

        [switch]$DryRun

    )

    $QueueItem.Started = Get-Date

    if(!(Test-Path $QueueItem.SourceFolder)){

        $QueueItem.Status = "Missing"

        $Script:CopyStatistics.MissingModels++

        return

    }

    $Images = Get-ImageFiles `
        $QueueItem.SourceFolder

    $QueueItem.Images = $Images.Count

    $Script:CopyStatistics.TotalImages += $Images.Count

    $Result = Invoke-RetryCopy `
        -Source $QueueItem.SourceFolder `
        -Destination $QueueItem.DestinationFolder `
        -DryRun:$DryRun

    if($Result){

        $QueueItem.Status = "Completed"

    }

    else{

        $QueueItem.Status = "Failed"

    }

    $QueueItem.Finished = Get-Date

    $Script:CopyStatistics.ProcessedFolders++

}

#############################################################
# Start Copy Engine
#############################################################

function Start-CopyEngine {

    param(

        [array]$Queue,

        [switch]$DryRun

    )

    $Current = 0

    $Total = $Queue.Count

    foreach($Item in $Queue){

        $Current++

        $Percent = [math]::Round(
            ($Current / $Total) * 100,
            2
        )

        Write-Progress `
            -Activity "Copying Images" `
            -Status "$Current of $Total" `
            -PercentComplete $Percent

        Invoke-CopyQueueItem `
            -QueueItem $Item `
            -DryRun:$DryRun

    }

    Write-Progress `
        -Activity "Copying Images" `
        -Completed

}

#############################################################
# Export Queue
#############################################################

function Export-CopyQueue {

    param(

        [array]$Queue,

        [string]$File

    )

    $Queue |

    Export-Csv `
        $File `
        -NoTypeInformation

}

#############################################################
# Get Failed Queue Items
#############################################################

function Get-FailedQueueItems {

    param(

        [array]$Queue

    )

    $Queue |

    Where-Object{

        $_.Status -eq "Failed"

    }

}

#############################################################
# Get Missing Models
#############################################################

function Get-MissingModels {

    param(

        [array]$Queue

    )

    $Queue |

    Where-Object{

        $_.Status -eq "Missing"

    }

}

#############################################################
# Copy Mode
#############################################################

$Script:CopyMode = "Overwrite"

function Set-CopyMode {

    param(
        [ValidateSet("Overwrite","Skip")]
        [string]$Mode = "Overwrite"
    )

    $Script:CopyMode = $Mode

}

#############################################################
# Save Resume Checkpoint
#############################################################

function Save-CopyCheckpoint {

    param(
        [array]$Queue,
        [string]$File
    )

    $Queue |
        ConvertTo-Json -Depth 5 |
        Set-Content $File

}

#############################################################
# Load Resume Checkpoint
#############################################################

function Load-CopyCheckpoint {

    param(
        [string]$File
    )

    if(Test-Path $File){

        return Get-Content $File -Raw |
            ConvertFrom-Json

    }

    return $null

}

#############################################################
# ETA
#############################################################

function Get-ETA {

    param(

        [datetime]$Start,

        [int]$Current,

        [int]$Total

    )

    if($Current -eq 0){

        return "--"

    }

    $Elapsed = (Get-Date) - $Start

    $SecondsPerItem = $Elapsed.TotalSeconds / $Current

    $Remaining = ($Total - $Current) * $SecondsPerItem

    return [timespan]::FromSeconds($Remaining)

}

#############################################################
# Processing Speed
#############################################################

function Get-CopySpeed {

    param(

        [datetime]$Start

    )

    $Elapsed = (Get-Date) - $Start

    if($Elapsed.TotalSeconds -le 0){

        return 0

    }

    return [math]::Round(

        $Script:CopyStatistics.CopiedImages /

        $Elapsed.TotalSeconds,

        2

    )

}

#############################################################
# Enhanced Engine
#############################################################

function Start-CopyEngine {

    param(

        [array]$Queue,

        [switch]$DryRun,

        [string]$CheckpointFile = ".\Resume.json"

    )

    $StartTime = Get-Date

    $Current = 0

    foreach($Item in $Queue){

        $Current++

        $Percent = [math]::Round(
            ($Current / $Queue.Count) * 100,
            2
        )

        $ETA = Get-ETA `
            -Start $StartTime `
            -Current $Current `
            -Total $Queue.Count

        $Speed = Get-CopySpeed `
            -Start $StartTime

        Write-Progress `
            -Activity "Copying Images" `
            -Status "$Current / $($Queue.Count) | ETA: $ETA | $Speed img/sec" `
            -PercentComplete $Percent

        Invoke-CopyQueueItem `
            -QueueItem $Item `
            -DryRun:$DryRun

        Save-CopyCheckpoint `
            -Queue $Queue `
            -File $CheckpointFile

        if(Get-Command Write-Log -ErrorAction Ignore){

            Write-Log "Copied $($Item.Model) -> $($Item.FSN)"

        }

    }

    Write-Progress `
        -Activity "Copying Images" `
        -Completed

}

#############################################################
# Summary
#############################################################

function Show-CopySummary {

    Write-Host ""
    Write-Host "===================================" -ForegroundColor Cyan
    Write-Host "COPY SUMMARY" -ForegroundColor Cyan
    Write-Host "===================================" -ForegroundColor Cyan

    Get-CopyStatistics |
        Format-List

}

#############################################################
# Export Module
#############################################################

Export-ModuleMember `
    -Function `
    Reset-CopyStatistics,

    Get-CopyStatistics,

    Test-ImageExtension,

    Test-SourceFolder,

    New-OutputFolder,

    Get-ImageFiles,

    Test-MappingRow,

    New-CopyQueue,

    Show-CopyPreview,

    Test-CopyQueue,

    Set-CopyMode,

    Start-CopyEngine,

    Export-CopyQueue,

    Get-FailedQueueItems,

    Get-MissingModels,

    Save-CopyCheckpoint,

    Load-CopyCheckpoint,

    Show-CopySummary
