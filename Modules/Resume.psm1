<#
============================================================
Image Distribution Manager Pro
Module : Resume.psm1
Version : 1.0
============================================================
#>

#region Variables

$Script:ResumeFile = ""

#endregion

#############################################################
# Initialize Resume
#############################################################

function Initialize-Resume {

    param(

        [string]$Folder

    )

    if(!(Test-Path $Folder)){

        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null

    }

    $Script:ResumeFile = Join-Path `
        $Folder `
        "Resume.json"

}

#############################################################
# Save Resume State
#############################################################

function Save-ResumeState {

    param(

        [array]$Queue

    )

    $Queue |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            $Script:ResumeFile `
            -Encoding UTF8

}

#############################################################
# Resume File Exists
#############################################################

function Test-ResumeAvailable {

    return Test-Path $Script:ResumeFile

}
#############################################################
# Load Resume State
#############################################################

function Load-ResumeState {

    if(!(Test-ResumeAvailable)){

        return $null

    }

    Get-Content `
        $Script:ResumeFile `
        -Raw |
    ConvertFrom-Json

}

#############################################################
# Remove Resume File
#############################################################

function Clear-ResumeState {

    if(Test-ResumeAvailable){

        Remove-Item `
            $Script:ResumeFile `
            -Force

    }

}

#############################################################
# Resume Queue
#############################################################

function Get-RemainingQueue {

    param(

        [array]$Queue

    )

    $Queue |

    Where-Object{

        $_.Status -ne "Completed"

    }

}
#############################################################
# Show Resume Information
#############################################################

function Show-ResumeSummary {

    if(!(Test-ResumeAvailable)){

        Write-Host ""

        Write-Host "No resume information found." `
            -ForegroundColor Yellow

        return

    }

    $Queue = Load-ResumeState

    $Completed = ($Queue |
        Where-Object{
            $_.Status -eq "Completed"
        }).Count

    $Pending = ($Queue |
        Where-Object{
            $_.Status -ne "Completed"
        }).Count

    Write-Host ""

    Write-Host "===================================" `
        -ForegroundColor Cyan

    Write-Host "Resume Information"

    Write-Host "===================================" `
        -ForegroundColor Cyan

    Write-Host ""

    Write-Host "Completed : $Completed"

    Write-Host "Remaining : $Pending"

    Write-Host ""

}

#############################################################
# Export
#############################################################

Export-ModuleMember `
-Function `
Initialize-Resume,
Save-ResumeState,
Load-ResumeState,
Clear-ResumeState,
Test-ResumeAvailable,
Get-RemainingQueue,
Show-ResumeSummary
