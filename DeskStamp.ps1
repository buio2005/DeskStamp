#requires -Version 5.1
<#
    DeskStamp
    ------------------------------------------------------------------
    Ogni giornata ha la sua cartella sul desktop.
    Every day gets its own folder on your desktop.

    Vive accanto all'orologio: nessuna finestra, nessuna installazione.
    Clic destro sull'icona per il menu.

    Le frasi non stanno qui dentro ma nella cartella lang: vedi lang/en.txt
    per aggiungere una lingua.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# --- nasconde la finestra della console ------------------------------------
Add-Type -Namespace Native -Name Finestra -MemberDefinition @'
[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
[DllImport("user32.dll")]   public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
'@
$hConsole = [Native.Finestra]::GetConsoleWindow()
if ($hConsole -ne [IntPtr]::Zero) { [void][Native.Finestra]::ShowWindow($hConsole, 0) }

$script:Radice = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
. (Join-Path $script:Radice 'DeskStamp-Core.ps1')

# --- una sola copia alla volta ---------------------------------------------
$nuovaIstanza = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\DeskStamp', [ref]$nuovaIstanza)
if (-not $nuovaIstanza) {
    [void][System.Windows.Forms.MessageBox]::Show((T 'msg.alreadyRunning'), 'DeskStamp')
    exit
}

# --- avvio automatico -------------------------------------------------------
$ChiaveRun = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$NomeRun   = 'DeskStamp'
$ValoreRun = '"{0}" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "{1}"' -f (Join-Path $PSHOME 'powershell.exe'), (Join-Path $script:Radice 'DeskStamp.ps1')
# vecchia voce dei tempi in cui il programma si chiamava DeskDay
Remove-ItemProperty -Path $ChiaveRun -Name 'DeskDay' -ErrorAction SilentlyContinue

function Test-AvvioAutomatico {
    $v = (Get-ItemProperty -Path $ChiaveRun -Name $NomeRun -ErrorAction SilentlyContinue).$NomeRun
    return ($null -ne $v)
}
function Set-AvvioAutomatico([bool]$attivo) {
    if ($attivo) { Set-ItemProperty -Path $ChiaveRun -Name $NomeRun -Value $ValoreRun }
    else { Remove-ItemProperty -Path $ChiaveRun -Name $NomeRun -ErrorAction SilentlyContinue }
}

# --- icona disegnata al volo: un foglietto di calendario con la D -----------
function New-IconaDeskStamp {
    $bmp = New-Object System.Drawing.Bitmap 32, 32
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.Clear([System.Drawing.Color]::Transparent)
    $blu    = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(30, 85, 155))
    $bianco = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
    $g.FillRectangle($blu, 2, 5, 28, 25)
    $g.FillRectangle($bianco, 2, 5, 28, 7)
    $g.FillRectangle($blu, 8, 2, 4, 6)
    $g.FillRectangle($blu, 20, 2, 4, 6)
    $font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $g.DrawString('D', $font, $bianco, 5, 10)
    $g.Dispose()
    return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

# --- stato iniziale ---------------------------------------------------------
try {
    Initialize-Stato
} catch {
    [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, 'DeskStamp')
    exit
}

# --- icona ------------------------------------------------------------------
$script:Contesto      = New-Object System.Windows.Forms.ApplicationContext
$script:Icona         = New-Object System.Windows.Forms.NotifyIcon
$script:Icona.Icon    = New-IconaDeskStamp
$script:Icona.Text    = T 'tray.active'
$script:Icona.Visible = $true

# --- menu -------------------------------------------------------------------
$menu = New-Object System.Windows.Forms.ContextMenuStrip

# riga di intestazione, non cliccabile: dice quale versione stai usando
$voceVersione = New-Object System.Windows.Forms.ToolStripMenuItem("DeskStamp $script:Versione")
$voceVersione.Enabled = $false
[void]$menu.Items.Add($voceVersione)
[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$script:VocePausa = New-Object System.Windows.Forms.ToolStripMenuItem
$script:VocePausa.add_Click({
    $script:InPausa = -not $script:InPausa
    $script:VocePausa.Checked = $script:InPausa
    Aggiorna-TestiMenu
    $script:Icona.Text = if ($script:InPausa) { T 'tray.paused' } else { T 'tray.active' }
    Scrivi $(if ($script:InPausa) { T 'log.paused' } else { T 'log.resumed' })
})
[void]$menu.Items.Add($script:VocePausa)

$script:VoceApri = New-Object System.Windows.Forms.ToolStripMenuItem
$script:VoceApri.add_Click({
    $c = Join-Path $script:Desktop (Get-NomeCartellaGiorno (Get-Date))
    if (Test-Path -LiteralPath $c) { Start-Process explorer.exe $c } else { Start-Process explorer.exe $script:Desktop }
})
[void]$menu.Items.Add($script:VoceApri)

$script:VoceUndo = New-Object System.Windows.Forms.ToolStripMenuItem
$script:VoceUndo.add_Click({ Start-Process -FilePath (Join-Path $script:Radice 'Undo.cmd') })
[void]$menu.Items.Add($script:VoceUndo)

[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$script:VoceEsclusioni = New-Object System.Windows.Forms.ToolStripMenuItem
$script:VoceEsclusioni.add_Click({
    if (-not (Test-Path -LiteralPath $script:FileEsclusioni)) { '' | Set-Content -LiteralPath $script:FileEsclusioni -Encoding UTF8 }
    Start-Process notepad.exe $script:FileEsclusioni
})
[void]$menu.Items.Add($script:VoceEsclusioni)

$script:VoceRicarica = New-Object System.Windows.Forms.ToolStripMenuItem
$script:VoceRicarica.add_Click({
    $script:Esclusioni = Get-Esclusioni
    $script:Ignorati = @{}
    $script:Icona.ShowBalloonTip(3000, 'DeskStamp', (T 'balloon.exclusionsReloaded' $script:Esclusioni.Count), [System.Windows.Forms.ToolTipIcon]::Info)
})
[void]$menu.Items.Add($script:VoceRicarica)

$script:VoceLog = New-Object System.Windows.Forms.ToolStripMenuItem
$script:VoceLog.add_Click({ if (Test-Path -LiteralPath $script:FileLog) { Start-Process notepad.exe $script:FileLog } })
[void]$menu.Items.Add($script:VoceLog)

[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

# sottomenu delle lingue: si costruisce da solo leggendo la cartella lang
$script:VoceLingua = New-Object System.Windows.Forms.ToolStripMenuItem
$script:VociLingua = @()
foreach ($f in @(Get-ChildItem -LiteralPath $script:CartellaLingue -Filter '*.txt' -ErrorAction SilentlyContinue | Sort-Object Name)) {
    $codice = [IO.Path]::GetFileNameWithoutExtension($f.Name)
    $tab    = Import-Lingua $codice
    $nome   = if ($tab['language.name']) { $tab['language.name'] } else { $codice }
    $voce   = New-Object System.Windows.Forms.ToolStripMenuItem($nome)
    $voce.Tag     = $codice
    $voce.Checked = ($codice -eq $script:Lingua)
    $voce.add_Click({
        $nuovo = $this.Tag
        Set-Lingua $nuovo
        Save-Lingua $nuovo
        foreach ($v in $script:VociLingua) { $v.Checked = ($v.Tag -eq $nuovo) }
        Aggiorna-TestiMenu
        Scrivi (T 'log.languageChanged' (T 'language.name'))
    })
    $script:VociLingua += $voce
    [void]$script:VoceLingua.DropDownItems.Add($voce)
}
[void]$menu.Items.Add($script:VoceLingua)

$script:VoceAvvio = New-Object System.Windows.Forms.ToolStripMenuItem
$script:VoceAvvio.Checked = Test-AvvioAutomatico
$script:VoceAvvio.add_Click({
    $nuovo = -not (Test-AvvioAutomatico)
    Set-AvvioAutomatico $nuovo
    $script:VoceAvvio.Checked = $nuovo
    Scrivi $(if ($nuovo) { T 'log.autostartOn' } else { T 'log.autostartOff' })
    $testo = if ($nuovo) { T 'balloon.autostartOn' } else { T 'balloon.autostartOff' }
    $script:Icona.ShowBalloonTip(3000, 'DeskStamp', $testo, [System.Windows.Forms.ToolTipIcon]::Info)
})
[void]$menu.Items.Add($script:VoceAvvio)

[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$script:VoceEsci = New-Object System.Windows.Forms.ToolStripMenuItem
$script:VoceEsci.add_Click({
    $script:Timer.Stop()
    $script:Icona.Visible = $false
    $script:Icona.Dispose()
    Scrivi (T 'log.quit')
    $script:Contesto.ExitThread()
})
[void]$menu.Items.Add($script:VoceEsci)

function Aggiorna-TestiMenu {
    $script:VocePausa.Text      = if ($script:InPausa) { T 'menu.resume' } else { T 'menu.pause' }
    $script:VoceApri.Text       = T 'menu.openToday'
    $script:VoceUndo.Text       = T 'menu.undo'
    $script:VoceEsclusioni.Text = T 'menu.editExclusions'
    $script:VoceRicarica.Text   = T 'menu.reloadExclusions'
    $script:VoceLog.Text        = T 'menu.openLog'
    $script:VoceLingua.Text     = T 'menu.language'
    $script:VoceAvvio.Text      = T 'menu.autostart'
    $script:VoceEsci.Text       = T 'menu.quit'
}
Aggiorna-TestiMenu

$script:Icona.ContextMenuStrip = $menu
$script:Icona.add_MouseDoubleClick({
    $c = Join-Path $script:Desktop (Get-NomeCartellaGiorno (Get-Date))
    if (Test-Path -LiteralPath $c) { Start-Process explorer.exe $c }
})

# --- il timer che fa girare tutto -------------------------------------------
$script:Timer = New-Object System.Windows.Forms.Timer
$script:Timer.Interval = 2000
$script:Timer.add_Tick({
    try {
        Invoke-Giro
        if ($script:CartellaNuova) {
            $script:Icona.ShowBalloonTip(4000, 'DeskStamp', (T 'balloon.dayFolder' $script:CartellaNuova), [System.Windows.Forms.ToolTipIcon]::Info)
            $script:CartellaNuova = $null
        }
        $script:Icona.Text = if ($script:InPausa) { T 'tray.paused' }
                             elseif ($script:Spostati -gt 0) { T 'tray.activeCount' $script:Spostati }
                             else { T 'tray.active' }
    } catch {
        Scrivi (T 'log.checkError' $_.Exception.Message) 'Red'
    }
})
$script:Timer.Start()

$script:Icona.ShowBalloonTip(3000, 'DeskStamp', (T 'balloon.running'), [System.Windows.Forms.ToolTipIcon]::Info)

[System.Windows.Forms.Application]::Run($script:Contesto)
$mutex.ReleaseMutex()
