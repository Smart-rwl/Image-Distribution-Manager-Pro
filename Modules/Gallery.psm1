<#
============================================================
Image Distribution Manager Pro
Module : Gallery.psm1
Version : 1.0
============================================================
#>

#region Variables

$Script:GalleryFolder = ""

#endregion

#############################################################
# Initialize Gallery
#############################################################

function Initialize-Gallery {

    param(

        [string]$Folder

    )

    $Script:GalleryFolder = $Folder

    if(!(Test-Path $Folder)){

        New-Item `
            -ItemType Directory `
            -Path $Folder `
            -Force | Out-Null

    }

}

#############################################################
# Get Image Files
#############################################################

function Get-GalleryImages {

    param(

        [string]$Folder

    )

    Get-ChildItem `
        $Folder `
        -File |

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
# Generate Gallery for One Folder
#############################################################

function New-FolderGallery {

    param(

        [string]$Folder

    )

    $Images = Get-GalleryImages $Folder

    $FSN = Split-Path $Folder -Leaf

    $Html = @()

    $Html += "<html>"
    $Html += "<head>"
    $Html += "<title>$FSN</title>"

    $Html += "<style>"

    $Html += "body{font-family:Segoe UI;background:#f5f5f5;margin:20px;}"

    $Html += ".card{display:inline-block;margin:12px;border:1px solid #ddd;background:white;padding:10px;text-align:center;}"

    $Html += "img{width:220px;height:220px;object-fit:contain;}"

    $Html += "</style>"

    $Html += "</head><body>"

    $Html += "<h2>$FSN</h2>"

    foreach($Image in $Images){

        $Html += "<div class='card'>"

        $Html += "<img src='$($Image.Name)'><br>"

        $Html += "$($Image.Name)"

        $Html += "</div>"

    }

    $Html += "</body></html>"

    $File = Join-Path `
        $Folder `
        "Gallery.html"

    $Html |

        Set-Content `
        $File `
        -Encoding UTF8

    return $File

}
#############################################################
# Generate Gallery for Entire Output
#############################################################

function New-Gallery {

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
            -Activity "Generating Galleries" `
            -Status "$Current / $($Folders.Count)" `
            -PercentComplete (
                ($Current/$Folders.Count)*100
            )

        New-FolderGallery `
            $Folder.FullName | Out-Null

    }

    Write-Progress `
        -Completed `
        -Activity "Gallery"

}

#############################################################
# Export Module
#############################################################

Export-ModuleMember `
-Function `
Initialize-Gallery,
Get-GalleryImages,
New-FolderGallery,
New-Gallery
