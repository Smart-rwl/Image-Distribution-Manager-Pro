<#
============================================================
Image Distribution Manager Pro
Module : UI.psm1
Version : 1.0
============================================================
#>

#############################################################
# Clear Screen
#############################################################

function Clear-Screen {

    Clear-Host

}

#############################################################
# Application Banner
#############################################################

function Show-Banner {

    Clear-Screen

    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "          IMAGE DISTRIBUTION MANAGER PRO"
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Version : 1.0"
    Write-Host "Author  : Ravinder Rawal"
    Write-Host ""

}

#############################################################
# Pause
#############################################################

function Pause-App {

    Write-Host ""
    Read-Host "Press ENTER to continue"

}

#############################################################
# Section Title
#############################################################

function Show-Title {

    param(
        [string]$Title
    )

    Write-Host ""
    Write-Host "----------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " $Title"
    Write-Host "----------------------------------------------------" -ForegroundColor DarkCyan

}
#############################################################
# Main Menu
#############################################################

function Show-MainMenu {

    Show-Banner

    Write-Host "1. Copy Images"
    Write-Host "2. Rename Images"
    Write-Host "3. Verify Images"
    Write-Host "4. Generate Reports"
    Write-Host "5. Create Gallery"
    Write-Host "6. Create ZIP Files"
    Write-Host "7. Backup"
    Write-Host "8. Resume"
    Write-Host "9. Settings"
    Write-Host "10. Run Complete Workflow"
    Write-Host "0. Exit"

    Write-Host ""

    return Read-Host "Select Option"

}

#############################################################
# Confirm
#############################################################

function Confirm-Action {

    param(
        [string]$Message
    )

    $Answer = Read-Host "$Message (Y/N)"

    return ($Answer.ToUpper() -eq "Y")

}

#############################################################
# Success Message
#############################################################

function Show-Success {

    param($Message)

    Write-Host ""
    Write-Host $Message -ForegroundColor Green

}

#############################################################
# Error Message
#############################################################

function Show-Error {

    param($Message)

    Write-Host ""
    Write-Host $Message -ForegroundColor Red

}
#############################################################
# Ask Folder
#############################################################

function Read-Folder {

    param(
        [string]$Title
    )

    Read-Host $Title

}

#############################################################
# Ask File
#############################################################

function Read-File {

    param(
        [string]$Title
    )

    Read-Host $Title

}

#############################################################
# Progress Header
#############################################################

function Show-Step {

    param(
        [string]$Step
    )

    Write-Host ""
    Write-Host ">> $Step" -ForegroundColor Yellow

}

#############################################################
# Export
#############################################################

Export-ModuleMember `
-Function `
Show-Banner,
Show-MainMenu,
Pause-App,
Show-Title,
Confirm-Action,
Show-Success,
Show-Error,
Read-Folder,
Read-File,
Show-Step,
Clear-Screen
