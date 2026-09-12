# DeskStamp

**Ogni giornata ha la sua cartella sul desktop.**

*[Read me in English](README.md)*

Quasi tutti usiamo il desktop come piano d'appoggio: download, schermate, PDF,
cartelle create al volo, tutto quello che serve a portata di mano per qualche
ora. Due giorni dopo è un muro di icone, e per far pulizia bisogna cancellare
un file alla volta.

DeskStamp sorveglia il desktop. Alla prima cosa nuova che ci arriva crea una
cartella con il nome del giorno — `2026-09-06 Domenica 6 Settembre` — e ci
sistema dentro tutto quello che segue. Domani vedrai la cartella di oggi: la
apri per ritrovare quello che hai fatto, oppure la elimini in un colpo solo.

Vive accanto all'orologio. Nessuna finestra, niente da installare, nessun
diritto di amministratore, nessun accesso a internet.

## Cosa non tocca mai

DeskStamp è prudente per scelta. Lascia stare:

- **Tutto quello che è già sul desktop quando parte.** La fotografia si rifà a
  ogni avvio, quindi agisce solo su ciò che compare mentre è in funzione:
  niente può sparire alle tue spalle.
- **I collegamenti** (`.lnk`, `.url`), così le icone che tieni lì restano lì.
- **File nascosti e di sistema**, e i file di servizio che i programmi creano
  accanto a un documento aperto (`~$...`, `.~lock....#`, `Thumbs.db`).
- **I download a metà** (`.crdownload`, `.part`, `.tmp`, …) finché il file non
  prende il nome definitivo.
- **I file che un programma tiene aperti.** Salvi un documento sul desktop e lo
  lasci aperto: DeskStamp aspetta e lo archivia quando chiudi il programma.
- **Le cartelle ancora chiamate "Nuova cartella"**, finché non le rinomini.
- **Quello che riporti indietro** da una cartella del giorno al desktop.
- **Le tue eccezioni**, elencate in `exclusions.txt` (si possono usare * e ?).

Ogni spostamento viene registrato, e **Annulla** rimette al loro posto gli
ultimi elementi archiviati.

## Installazione

1. Scarica lo zip, https://github.com/buio2005/DeskStamp/releases/latest/download/DeskStamp-source.zip estrai la cartella e avvia Start-DeskStamp.cmd
2. **Tasto destro sullo ZIP → Proprietà → spunta "Annulla blocco" → OK, prima di
   estrarre.** L'estrazione funziona comunque: quella spunta serve a evitare
   l'avviso di sicurezza che Windows mostra al primo avvio dei file scaricati.
3. Estrai la cartella dove preferisci.
4. Sistema il desktop come vuoi che resti: quello che c'è al momento
   dell'avvio diventa intoccabile.
5. Lancia `Start-DeskStamp.cmd`. Vicino all'orologio compare un'icona blu a
   forma di calendario; se finisce dietro la freccetta `^`, trascinala
   nell'area visibile.

Non ti fidi ancora? Lancia `Dry-Run.cmd`: apre una finestra e scrive cosa
*avrebbe* archiviato, senza toccare un solo file.

## Il menu dell'icona

| Voce | Cosa fa |
| --- | --- |
| Metti in pausa | Sospende la sorveglianza |
| Apri la cartella di oggi | Anche con doppio clic sull'icona |
| Annulla gli ultimi spostamenti | Elenca gli ultimi e propone di rimetterli |
| Modifica le esclusioni | Apre `exclusions.txt` |
| Rileggi le esclusioni | Applica le modifiche senza riavviare |
| Apri il diario | Mostra cosa ha fatto DeskStamp |
| Lingua / Language | Cambia lingua, la scelta viene ricordata |
| Avvia con Windows | Lo fa partire all'accensione |
| Esci | Lo chiude |

## Lingua

DeskStamp parte nella lingua di Windows se esiste la traduzione, altrimenti in
inglese, e la si cambia dal menu in qualsiasi momento.

**Per aggiungere una lingua** copia `lang/en.txt`, chiamalo con il codice di due
lettere della lingua (`fr.txt`, `de.txt`, …) e traduci solo la parte a destra
del segno uguale. Comparirà nel menu al riavvio, senza toccare una riga di
codice.

Le cartelle del giorno cominciano sempre con la data in formato ISO
(`2026-09-06 …`), quindi cambiando lingua quelle già create restano
riconosciute e ordinate.

## Requisiti

Windows con PowerShell 5.1, incluso in Windows 10 e 11. Il percorso del desktop
viene chiesto a Windows, quindi funziona anche con il desktop reindirizzato su
OneDrive.

## Perché PowerShell e non un programma compilato

DeskStamp sposta file sul tuo computer. Hai il diritto di controllare cosa fa
davvero, e uno script PowerShell si legge in chiaro: apri `DeskStamp-Core.ps1`
e in dieci minuti verifichi che non tocchi altro. Un `.exe` sembrerebbe più
professionale e ti direbbe molto meno.

## Licenza

MIT — vedi [LICENSE](LICENSE).
