<#
============================================================
Image Distribution Manager Pro
Module : Reports.psm1
Version : 1.0
============================================================
#>

#region Report Variables

$Script:ReportPath = ""
$Script:TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"

#endregion

#############################################################
# Initialize Reports Folder
#############################################################

function Initialize-Reports {

    param(

        [string]$Folder

    )

    $Script:ReportPath = $Folder

    if(!(Test-Path $Folder)){

        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null

    }

}

#############################################################
# Report Filename
#############################################################

function Get-ReportFile {

    param(

        [string]$Name,

        [string]$Extension="csv"

    )

    Join-Path `
        $Script:ReportPath `
        ("{0}_{1}.{2}" -f `
            $Name,
            $Script:TimeStamp,
            $Extension)

}

#############################################################
# Export CSV
#############################################################

function Export-CSVReport {

    param(

        [array]$Data,

        [string]$Name

    )

    $File = Get-ReportFile `
        -Name $Name `
        -Extension "csv"

    $Data |

        Export-Csv `
        $File `
        -NoTypeInformation `
        -Encoding UTF8

    return $File

}

#############################################################
# Export JSON
#############################################################

function Export-JSONReport {

    param(

        $Data,

        [string]$Name

    )

    $File = Get-ReportFile `
        -Name $Name `
        -Extension "json"

    $Data |

        ConvertTo-Json -Depth 10 |

        Set-Content `
        $File `
        -Encoding UTF8

    return $File

}
#############################################################
# Missing Model Report
#############################################################

function Export-MissingModelReport {

    param(

        [array]$Queue

    )

    $Missing = $Queue |

        Where-Object{

            $_.Status -eq "Missing"

        }

    Export-CSVReport `
        -Data $Missing `
        -Name "Missing_Models"

}

#############################################################
# Failed Copy Report
#############################################################

function Export-FailedCopyReport {

    param(

        [array]$Queue

    )

    $Failed = $Queue |

        Where-Object{

            $_.Status -eq "Failed"

        }

    Export-CSVReport `
        $Failed `
        "Failed_Copy"

}

#############################################################
# Duplicate Report
#############################################################

function Export-DuplicateReport {

    param(

        [array]$Duplicates

    )

    Export-CSVReport `
        $Duplicates `
        "Duplicate_Images"

}

#############################################################
# Verification Report
#############################################################

function Export-VerificationReport {

    param(

        [array]$Verification

    )

    Export-CSVReport `
        $Verification `
        "Verification"

}
#############################################################
# HTML Summary
#############################################################

function Export-HTMLSummary {

    param(

        $Statistics

    )

    $File = Get-ReportFile `
        "Summary" `
        "html"

    $Html = @"

<html>

<head>

<title>Image Distribution Report</title>

<style>

body{

font-family:Segoe UI;

margin:30px;

}

table{

border-collapse:collapse;

}

td,th{

border:1px solid #ccc;

padding:8px;

}

th{

background:#0078D7;

color:white;

}

</style>

</head>

<body>

<h2>Image Distribution Manager Report</h2>

$(

$Statistics |

ConvertTo-Html -Fragment

)

</body>

</html>

"@

    $Html |

        Set-Content `
        $File `
        -Encoding UTF8

    return $File

}

#############################################################
# Generate All Reports
#############################################################

function Generate-AllReports {

    param(

        [array]$Queue,

        [array]$Verification,

        $Statistics

    )

    Export-MissingModelReport $Queue

    Export-FailedCopyReport $Queue

    Export-VerificationReport $Verification

    Export-JSONReport `
        $Statistics `
        "Statistics"

    Export-HTMLSummary `
        $Statistics

}

#############################################################
# Export Module
#############################################################

Export-ModuleMember -Function *
