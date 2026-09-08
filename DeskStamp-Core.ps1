#requires -Version 5.1
<#
    DeskStamp - Core
    ------------------------------------------------------------------
    Funzioni condivise dai tre script. Non si lancia da solo.
    Shared functions. Not meant to be run on its own.

    Chi lo include deve prima impostare $script:Radice con la cartella
    del programma, poi fare:  . (Join-Path $script:Radice 'DeskStamp-Core.ps1')
#>

if (-not $script:Radice) { $script:Radice = $PSScriptRoot }

$script:CartellaLingue   = Join-Path $script:Radice 'lang'
$script:FileImpostazioni = Join-Path $script:Radice 'deskstamp-settings.txt'
$script:FileEsclusioni   = Join-Path $script:Radice 'exclusions.txt'
$script:FileRegistro     = Join-Path $script:Radice 'deskstamp-moves.txt'
$script:FileFotografia   = Join-Path $script:Radice 'deskstamp-snapshot.txt'
$script:FileLog          = Join-Path $script:Radice 'deskstamp-log.txt'

$script:Console       = $false   # true solo nella versione a finestra
$script:Simulazione   = $false   # true = non sposta nulla, scrive solo
$script:InPausa       = $false
$script:Spostati      = 0
$script:CartellaNuova = $null    # valorizzata quando nasce la cartella di un nuovo giorno
$script:SecondiStabilita = 3

# ================================================================== lingua

function Get-LinguaSalvata {
    if (Test-Path -LiteralPath $script:FileImpostazioni) {
        foreach ($r in @(Get-Content -LiteralPath $script:FileImpostazioni -Encoding UTF8)) {
            if ($r -match '^\s*language\s*=\s*([A-Za-z]{2})') { return $Matches[1].ToLower() }
        }
    }
    return $null
}

function Save-Lingua([string]$codice) {
    "language = $codice" | Set-Content -LiteralPath $script:FileImpostazioni -Encoding UTF8
}

# Legge un file lang\xx.txt fatto di righe "chiave = testo".
function Import-Lingua([string]$codice) {
    $file = Join-Path $script:CartellaLingue "$codice.txt"
    if (-not (Test-Path -LiteralPath $file)) { $file = Join-Path $script:CartellaLingue 'en.txt' }
    $tabella = @{}
    foreach ($r in @(Get-Content -LiteralPath $file -Encoding UTF8)) {
        $riga = $r.Trim()
        if ($riga -eq '' -or $riga.StartsWith('#')) { continue }
        $i = $riga.IndexOf('=')
        if ($i -lt 1) { continue }
        $chiave = $riga.Substring(0, $i).Trim()
        $valore = $riga.Substring($i + 1).Trim() -replace '\\n', "`n"
        $tabella[$chiave] = $valore
    }
    return $tabella
}

function Set-Lingua([string]$codice) {
    $script:Lingua     = $codice
    $script:Testi      = Import-Lingua $codice
    $script:GiorniNomi = @(($script:Testi['date.days']   -split ',') | ForEach-Object { $_.Trim() })
    $script:MesiNomi   = @(($script:Testi['date.months'] -split ',') | ForEach-Object { $_.Trim() })
}

# T 'chiave' valore1 valore2  ->  restituisce la frase tradotta e completata
function T {
    param([string]$chiave)
    $v = $script:Testi[$chiave]
    if ($null -eq $v) { return $chiave }
    if ($args.Count -gt 0) { return [string]::Format($v, [object[]]$args) }
    return $v
}

# Lingua di partenza: quella salvata, altrimenti quella di Windows, altrimenti inglese.
$codiceIniziale = Get-LinguaSalvata
if (-not $codiceIniziale) {
    $codiceIniziale = (Get-Culture).TwoLetterISOLanguageName.ToLower()
    if (-not (Test-Path -LiteralPath (Join-Path $script:CartellaLingue "$codiceIniziale.txt"))) { $codiceIniziale = 'en' }
}
Set-Lingua $codiceIniziale

# ================================================================== regole

$script:RegexCartellaGiorno   = '^\d{4}-\d{2}-\d{2}\s'
$script:EstensioniTemporanee  = @('.crdownload','.part','.partial','.tmp','.temp','.opdownload','.download','.!ut')
$script:EstensioniMaiSpostare = @('.lnk','.url')
$script:NomiIgnorati          = @('desktop.ini')
$script:NomiTecnici           = @('~$*','.~lock.*','Thumbs.db','.DS_Store','*.crdownload','*.part')
# Nomi provvisori in piu' lingue: valgono sempre, qualunque lingua sia attiva.
$script:NomiProvvisori        = @('Nuova cartella*','Nuovo documento*','New folder*','New Text Document*',
                                  'Nouveau dossier*','Neuer Ordner*','Nueva carpeta*','Nova pasta*')

# ================================================================== utilita'

function Scrivi([string]$Testo, [string]$Colore = 'Gray') {
    $riga = '{0:HH:mm:ss}  {1}' -f (Get-Date), $Testo
    if ($script:Console) { Write-Host $riga -ForegroundColor $Colore }
    try { Add-Content -LiteralPath $script:FileLog -Value $riga -Encoding UTF8 } catch { }
}

# Il Desktop non e' sempre in C:\Users\<nome>\Desktop: puo' essere
# reindirizzato (tipicamente su OneDrive). Lo chiediamo a Windows.
function Get-PercorsoDesktop {
    $p = [Environment]::GetFolderPath('DesktopDirectory')
    if ([string]::IsNullOrWhiteSpace($p)) {
        $k = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
        $p = [Environment]::ExpandEnvironmentVariables($k.Desktop)
    }
    return $p
}

function Get-NomeCartellaGiorno([datetime]$d) {
    '{0:yyyy-MM-dd} {1} {2} {3}' -f $d, $script:GiorniNomi[[int]$d.DayOfWeek], $d.Day, $script:MesiNomi[$d.Month - 1]
}

function Test-CorrispondeAModello([string]$nome, $modelli) {
    foreach ($m in $modelli) { if ($nome -like $m) { return $true } }
    return $false
}

function Get-Esclusioni {
    if (-not (Test-Path -LiteralPath $script:FileEsclusioni)) { return @() }
    @(Get-Content -LiteralPath $script:FileEsclusioni -Encoding UTF8 |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -ne '' -and -not $_.StartsWith('#') })
}

# Prova ad aprire il file in modo esclusivo: se fallisce, qualcuno lo tiene aperto.
function Test-FileLibero([string]$percorso) {
    try {
        $fs = [System.IO.File]::Open($percorso, 'Open', 'ReadWrite', 'None')
        $fs.Close(); $fs.Dispose()
        return $true
    } catch { return $false }
}

function Test-CartellaLibera([string]$percorso) {
    foreach ($f in @(Get-ChildItem -LiteralPath $percorso -Force -Recurse -File -ErrorAction SilentlyContinue)) {
        if (-not (Test-FileLibero $f.FullName)) { return $false }
    }
    return $true
}

# "Firma": se cambia da un giro all'altro l'elemento sta ancora crescendo o e' in rinomina.
function Get-Firma($elemento) {
    if ($elemento.PSIsContainer) {
        $n = @(Get-ChildItem -LiteralPath $elemento.FullName -Force -ErrorAction SilentlyContinue).Count
        return '{0}|{1}|{2}' -f $elemento.Name, $n, $elemento.LastWriteTimeUtc.Ticks
    }
    return '{0}|{1}|{2}' -f $elemento.Name, $elemento.Length, $elemento.LastWriteTimeUtc.Ticks
}

function Get-DestinazioneLibera([string]$cartella, [string]$nome) {
    $dest = Join-Path $cartella $nome
    if (-not (Test-Path -LiteralPath $dest)) { return $dest }
    $base = [IO.Path]::GetFileNameWithoutExtension($nome)
    $est  = [IO.Path]::GetExtension($nome)
    $i = 2
    while ($true) {
        $dest = Join-Path $cartella ('{0} ({1}){2}' -f $base, $i, $est)
        if (-not (Test-Path -LiteralPath $dest)) { return $dest }
        $i++
    }
}

function Segnala-Ignorato([string]$percorso, [string]$nome, [string]$motivo) {
    if (-not $script:Ignorati.ContainsKey($percorso)) {
        $script:Ignorati[$percorso] = $true
        Scrivi (T 'log.ignored' $motivo $nome) 'DarkGray'
    }
}

# ================================================================== stato

function Initialize-Stato {
    $script:Desktop = Get-PercorsoDesktop
    if (-not (Test-Path -LiteralPath $script:Desktop)) { throw (T 'msg.desktopNotFound' $script:Desktop) }

    # La fotografia si rifa' a ogni avvio: cio' che c'e' adesso e' intoccabile.
    $nomi = @(Get-ChildItem -LiteralPath $script:Desktop -Force -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    $nomi | Set-Content -LiteralPath $script:FileFotografia -Encoding UTF8
    $script:Fotografia = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($n in $nomi) { [void]$script:Fotografia.Add($n) }

    # Registro degli spostamenti gia' fatti: se uno ricompare sul desktop
    # vuol dire che ce l'ha rimesso l'utente, e non va toccato.
    $script:GiaSpostati = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
    if (Test-Path -LiteralPath $script:FileRegistro) {
        foreach ($r in @(Get-Content -LiteralPath $script:FileRegistro -Encoding UTF8)) {
            $c = $r -split "`t"
            if ($c.Count -ge 2) { [void]$script:GiaSpostati.Add((Split-Path -Leaf $c[1])) }
        }
    }

    $script:Esclusioni = Get-Esclusioni
    $script:Tracciati  = @{}
    $script:Ignorati   = @{}

    Scrivi (T 'log.started') 'Cyan'
    Scrivi (T 'log.startedInfo' $script:Desktop $script:Fotografia.Count $script:GiaSpostati.Count) 'Cyan'
}

# ================================================================== il cuore

function Invoke-Giro {
    if ($script:InPausa) { return }
    $adesso   = Get-Date
    $presenti = @{}

    foreach ($el in @(Get-ChildItem -LiteralPath $script:Desktop -Force -ErrorAction SilentlyContinue)) {
        $nome = $el.Name
        $presenti[$el.FullName] = $true

        # --- filtri silenziosi
        if ($script:Fotografia.Contains($nome)) { continue }
        if ($el.PSIsContainer -and $nome -match $script:RegexCartellaGiorno) { continue }
        if ($script:NomiIgnorati -contains $nome.ToLower()) { continue }

        # --- filtri motivati, scritti nel diario una volta sola
        if (Test-CorrispondeAModello $nome $script:NomiTecnici) {
            Segnala-Ignorato $el.FullName $nome (T 'reason.serviceFile'); continue
        }
        if (($el.Attributes -band [IO.FileAttributes]::Hidden) -or ($el.Attributes -band [IO.FileAttributes]::System)) {
            Segnala-Ignorato $el.FullName $nome (T 'reason.hiddenSystem'); continue
        }
        if (-not $el.PSIsContainer) {
            $est = $el.Extension.ToLower()
            if ($script:EstensioniTemporanee -contains $est) {
                Segnala-Ignorato $el.FullName $nome (T 'reason.downloading'); continue
            }
            if ($script:EstensioniMaiSpostare -contains $est) {
                Segnala-Ignorato $el.FullName $nome (T 'reason.shortcut'); continue
            }
        }
        if (Test-CorrispondeAModello $nome $script:NomiProvvisori) {
            Segnala-Ignorato $el.FullName $nome (T 'reason.needsName'); continue
        }
        if ($script:GiaSpostati.Contains($nome)) {
            Segnala-Ignorato $el.FullName $nome (T 'reason.alreadyArchived'); continue
        }
        if (Test-CorrispondeAModello $nome $script:Esclusioni) {
            Segnala-Ignorato $el.FullName $nome (T 'reason.excluded'); continue
        }

        # --- elemento nuovo: lo seguiamo finche' non si ferma
        $firma = Get-Firma $el
        if (-not $script:Tracciati.ContainsKey($el.FullName)) {
            $script:Tracciati[$el.FullName] = @{ Firma = $firma; Da = $adesso; Segnalato = $false; Fatto = $false }
            Scrivi (T 'log.detected' $nome) 'White'
            continue
        }

        $t = $script:Tracciati[$el.FullName]
        if ($t.Fatto) { continue }
        if ($t.Firma -ne $firma) { $t.Firma = $firma; $t.Da = $adesso; continue }
        if (($adesso - $t.Da).TotalSeconds -lt $script:SecondiStabilita) { continue }

        # --- fermo da abbastanza: qualcuno lo tiene aperto?
        $libero = if ($el.PSIsContainer) { Test-CartellaLibera $el.FullName } else { Test-FileLibero $el.FullName }
        if (-not $libero) {
            if (-not $t.Segnalato) { Scrivi (T 'log.waiting' $nome) 'DarkYellow'; $t.Segnalato = $true }
            continue
        }
        if ($t.Segnalato) { Scrivi (T 'log.nowFree' $nome) 'White' }

        $nomeGiorno     = Get-NomeCartellaGiorno $adesso
        $cartellaGiorno = Join-Path $script:Desktop $nomeGiorno

        if ($script:Simulazione) {
            Scrivi (T 'log.wouldMove' $nome ($nomeGiorno + '\')) 'Yellow'
            $t.Fatto = $true
            continue
        }

        if (-not (Test-Path -LiteralPath $cartellaGiorno)) {
            New-Item -ItemType Directory -Path $cartellaGiorno | Out-Null
            Scrivi (T 'log.dayFolderCreated' $nomeGiorno) 'Green'
            $script:CartellaNuova = $nomeGiorno
        }
        $dest = Get-DestinazioneLibera $cartellaGiorno $nome
        try {
            Move-Item -LiteralPath $el.FullName -Destination $dest
            $stampo = '{0:yyyy-MM-dd HH:mm:ss}' -f (Get-Date)
            Add-Content -LiteralPath $script:FileRegistro -Value ($stampo + "`t" + $el.FullName + "`t" + $dest) -Encoding UTF8
            [void]$script:GiaSpostati.Add($nome)
            $script:Spostati++
            Scrivi (T 'log.moved' $nome ($nomeGiorno + '\' + (Split-Path -Leaf $dest))) 'Green'
            $script:Tracciati.Remove($el.FullName)
        } catch {
            Scrivi (T 'log.moveError' $nome $_.Exception.Message) 'Red'
            $t.Da = $adesso
        }
    }

    foreach ($k in @($script:Tracciati.Keys)) { if (-not $presenti.ContainsKey($k)) { $script:Tracciati.Remove($k) } }
    foreach ($k in @($script:Ignorati.Keys))  { if (-not $presenti.ContainsKey($k)) { $script:Ignorati.Remove($k) } }
}
