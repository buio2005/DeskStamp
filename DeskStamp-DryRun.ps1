#requires -Version 5.1
<#
    DeskStamp - modalita' prova / dry run
    ------------------------------------------------------------------
    Non sposta nulla: mostra a video e nel diario cosa farebbe.
    Moves nothing: shows on screen and in the log what it would do.
#>

param([int]$IntervalloSecondi = 2)

$ErrorActionPreference = 'Stop'
$script:Radice = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
. (Join-Path $script:Radice 'DeskStamp-Core.ps1')

$script:Console     = $true
$script:Simulazione = $true

try { $Host.UI.RawUI.WindowTitle = T 'dryrun.title' } catch { }

Initialize-Stato
Scrivi (T 'dryrun.mode') 'Green'
Scrivi ('{0}: {1}' -f (T 'menu.openToday'), (Get-NomeCartellaGiorno (Get-Date))) 'Cyan'
Scrivi (T 'dryrun.stop') 'Cyan'
Write-Host ''

while ($true) {
    Start-Sleep -Seconds $IntervalloSecondi
    try { Invoke-Giro } catch { Scrivi (T 'log.checkError' $_.Exception.Message) 'Red' }
}
