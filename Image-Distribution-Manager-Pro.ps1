<#
============================================================
Image Distribution Manager Pro
Main Application
Version : 1.0
============================================================
#>

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

# Import Modules
$Modules = @(
    "Logger.psm1",
    "UI.psm1",
    "Backup.psm1",
    "Resume.psm1",
    "Copy.psm1",
    "Rename.psm1",
    "Verify.psm1",
    "Reports.psm1",
    "Gallery.psm1",
    "Zip.psm1"
)

foreach ($Module in $Modules) {

    Import-Module (
        Join-Path $Root "Modules\$Module"
    ) -Force

}

# Initialize

Initialize-Logger "$Root\Logs"
Initialize-Backup "$Root\Backups"
Initialize-Gallery "$Root\Gallery"
Initialize-Zip "$Root\ZIP"
Initialize-Resume "$Root\Projects"

Start-LogSession

Show-Banner

# Ask User

$SourceFolder = Read-Folder "Source Folder"
$CSVFile      = Read-File   "Mapping CSV"
$OutputFolder = Read-Folder "Output Folder"

# Load Mapping

$Mappings = Import-Csv $CSVFile

# Build Queue

$Queue = New-CopyQueue `
    -Mappings $Mappings `
    -SourceRoot $SourceFolder `
    -OutputRoot $OutputFolder

do{

    $Choice = Show-MainMenu

    switch($Choice){

        "1"{

            Start-CopyEngine $Queue

            Pause-App

        }

        "2"{

            Start-RenameEngine `
                $OutputFolder

            Pause-App

        }

        "3"{

            $Verification = Start-Verification `
                $OutputFolder

            Pause-App

        }

        "4"{

            Initialize-Reports `
                "$Root\Reports"

            Generate-AllReports `
                $Queue `
                $Verification `
                (Get-CopyStatistics)

            Pause-App

        }

        "5"{

            New-Gallery `
                $OutputFolder

            Pause-App

        }

        "6"{

            Compress-Output `
                $OutputFolder

            Pause-App

        }

        "7"{

            Backup-Folder `
                $OutputFolder

            Pause-App

        }

        "8"{

            Show-ResumeSummary

            Pause-App

        }

        "9"{

            notepad "$Root\settings.json"

        }

        "10"{

            Backup-Folder $OutputFolder

            Start-CopyEngine $Queue

            Start-RenameEngine $OutputFolder

            $Verification = Start-Verification `
                $OutputFolder

            Initialize-Reports `
                "$Root\Reports"

            Generate-AllReports `
                $Queue `
                $Verification `
                (Get-CopyStatistics)

            New-Gallery `
                $OutputFolder

            Compress-Output `
                $OutputFolder

            Show-CopySummary

            Pause-App

        }

        "0"{

            break

        }

    }

}while($Choice -ne "0")

Stop-LogSession
