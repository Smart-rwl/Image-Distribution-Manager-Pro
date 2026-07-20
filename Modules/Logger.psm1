<#
============================================================
Image Distribution Manager Pro
Module : Logger.psm1
Version : 1.0
============================================================
#>

#region Variables

$Script:LogFolder = ""
$Script:LogFile = ""

#endregion

#############################################################
# Initialize Logger
#############################################################

function Initialize-Logger {

    param(

        [string]$Folder

    )

    $Script:LogFolder = $Folder

    if(!(Test-Path $Folder)){

        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null

    }

    $Script:LogFile = Join-Path `
        $Folder `
        ("Run_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")

}
#############################################################
# Write Log
#############################################################

function Write-Log {

    param(

        [string]$Message,

        [ValidateSet("INFO","WARNING","ERROR","SUCCESS")]

        [string]$Level="INFO"

    )

    $Time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $Line = "[{0}] [{1}] {2}" -f `
        $Time,
        $Level,
        $Message

    Add-Content `
        $Script:LogFile `
        $Line

}

#############################################################
# Console + Log
#############################################################

function Write-Info {

    param($Message)

    Write-Host $Message -ForegroundColor White

    Write-Log `
        $Message `
        "INFO"

}

function Write-Success {

    param($Message)

    Write-Host $Message -ForegroundColor Green

    Write-Log `
        $Message `
        "SUCCESS"

}

function Write-WarningLog {

    param($Message)

    Write-Host $Message -ForegroundColor Yellow

    Write-Log `
        $Message `
        "WARNING"

}

function Write-ErrorLog {

    param($Message)

    Write-Host $Message -ForegroundColor Red

    Write-Log `
        $Message `
        "ERROR"

}
#############################################################
# Session Header
#############################################################

function Start-LogSession {

    Write-Log "========================================"
    Write-Log "Image Distribution Manager Pro Started"
    Write-Log "Computer : $env:COMPUTERNAME"
    Write-Log "User     : $env:USERNAME"
    Write-Log "PowerShell : $($PSVersionTable.PSVersion)"
    Write-Log "========================================"

}

#############################################################
# Session Footer
#############################################################

function Stop-LogSession {

    Write-Log "========================================"
    Write-Log "Application Finished"
    Write-Log "========================================"

}

#############################################################
# Get Current Log File
#############################################################

function Get-LogFile{

    return $Script:LogFile

}

#############################################################
# Export Module
#############################################################

Export-ModuleMember `
-Function `
Initialize-Logger,
Write-Log,
Write-Info,
Write-Success,
Write-WarningLog,
Write-ErrorLog,
Start-LogSession,
Stop-LogSession,
Get-LogFile
