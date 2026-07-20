Clear-Host

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-Module "$Root\Modules\Config.psm1" -Force
Import-Module "$Root\Modules\Logger.psm1" -Force
Import-Module "$Root\Modules\UI.psm1" -Force

Initialize-Application

Start-MainMenu
