#requires -Version 5.1
<#
    DeskStamp - Annulla / Undo
    Rimette sul desktop gli ultimi elementi archiviati.
    Uso:  Undo.cmd            (ultimi 10 / last 10)
          .\DeskStamp-Undo.ps1 -Ultimi 30
#>

param([int]$Ultimi = 10)

$ErrorActionPreference = 'Stop'
$script:Radice = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
. (Join-Path $script:Radice 'DeskStamp-Core.ps1')

try { $Host.UI.RawUI.WindowTitle = T 'undo.title' } catch { }

if (-not (Test-Path -LiteralPath $script:FileRegistro)) {
    Write-Host (T 'undo.noRegistry') -ForegroundColor Yellow
    return
}

$righe = @(Get-Content -LiteralPath $script:FileRegistro -Encoding UTF8 | Where-Object { $_.Trim() -ne '' })
if ($righe.Count -eq 0) {
    Write-Host (T 'undo.emptyRegistry') -ForegroundColor Yellow
    return
}

$da        = [Math]::Max(0, $righe.Count - $Ultimi)
$candidati = @()
foreach ($r in $righe[$da..($righe.Count - 1)]) {
    $c = $r -split "`t"
    if ($c.Count -ge 3) { $candidati += [pscustomobject]@{ Data = $c[0]; Origine = $c[1]; Destinazione = $c[2] } }
}

Write-Host ''
Write-Host (T 'undo.header' $candidati.Count) -ForegroundColor Cyan
$i = 1
foreach ($c in $candidati) {
    $stato = if (Test-Path -LiteralPath $c.Destinazione) { '' } else { '  ' + (T 'undo.missing') }
    Write-Host ('  {0,2}. {1}  {2}{3}' -f $i, $c.Data, (Split-Path -Leaf $c.Destinazione), $stato)
    $i++
}
Write-Host ''
$risposta = Read-Host (T 'undo.confirm')
if ($risposta -notmatch (T 'undo.yesPattern')) {
    Write-Host (T 'undo.cancelled') -ForegroundColor Yellow
    return
}

$fatti = 0
foreach ($c in $candidati) {
    if (-not (Test-Path -LiteralPath $c.Destinazione)) { continue }
    if (Test-Path -LiteralPath $c.Origine) {
        Write-Host (T 'undo.skip' (Split-Path -Leaf $c.Origine)) -ForegroundColor Yellow
        continue
    }
    try {
        Move-Item -LiteralPath $c.Destinazione -Destination $c.Origine
        Write-Host (T 'undo.restored' (Split-Path -Leaf $c.Origine)) -ForegroundColor Green
        Scrivi ('UNDO: {0}' -f (Split-Path -Leaf $c.Origine))
        $fatti++
    } catch {
        Write-Host (T 'undo.error' (Split-Path -Leaf $c.Origine) $_.Exception.Message) -ForegroundColor Red
    }
}
Write-Host ''
Write-Host (T 'undo.done' $fatti) -ForegroundColor Cyan
Write-Host ''
[void](Read-Host (T 'undo.close'))
