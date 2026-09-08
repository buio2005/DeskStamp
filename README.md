# DeskStamp

**Every day gets its own folder on your desktop.**

*[Leggimi in italiano](README.it.md)*

Most of us use the Windows desktop as a landing strip: downloads, screenshots,
PDFs, quick folders — anything we need within reach for a few hours. Two days
later it is a wall of icons, and cleaning it up means deleting files one by one.

DeskStamp watches your desktop. The first time something new lands there, it
creates a folder named after the day — `2026-09-06 Sunday 6 September` — and
files everything that follows into it. Tomorrow you see yesterday's folder: open
it to find what you did, or delete it in one move.

It runs from the notification area, next to the clock. No window, no installer,
no administrator rights, no network access.

## What it never moves

DeskStamp is deliberately cautious. It leaves alone:

- **Anything already on the desktop when it starts.** The snapshot is taken at
  every launch, so DeskStamp only ever acts on what appears while it is running.
  Nothing can disappear behind your back.
- **Shortcuts** (`.lnk`, `.url`), so the icons you keep stay where they are.
- **Hidden and system files**, and the working files programs create next to an
  open document (`~$...`, `.~lock....#`, `Thumbs.db`).
- **Downloads in progress** (`.crdownload`, `.part`, `.tmp`, …) until the file
  takes its final name.
- **Files a program still holds open.** Save a document to the desktop and keep
  it open: DeskStamp waits, and files it the moment you close the program.
- **Items still named `New folder`**, in any of the supported languages, until
  you rename them.
- **Anything you drag back out** of a day folder onto the desktop.
- **Your own exceptions**, listed in `exclusions.txt` (wildcards allowed).

Every move is recorded, and **Undo** puts recent items back where they came from.

## Install

1. Download the ZIP.
2. **Right-click the ZIP → Properties → tick "Unblock" → OK.** Do this *before*
   extracting, or Windows will refuse to run the scripts.
3. Extract the folder anywhere you like.
4. Tidy your desktop the way you want it to stay — what is there at launch
   becomes untouchable.
5. Run `Start-DeskStamp.cmd`. A blue calendar icon appears near the clock; if it
   hides behind the `^` arrow, drag it into the visible area.

Not sure yet? Run `Dry-Run.cmd` instead: it opens a console window and writes
down what it *would* file, without touching a single file.

## The tray menu

Right-click the icon:

| Item | What it does |
| --- | --- |
| Pause | Suspends watching |
| Open today's folder | Also on double-click |
| Undo recent moves | Lists the last moves and offers to put them back |
| Edit exclusions | Opens `exclusions.txt` |
| Reload exclusions | Applies your edits without restarting |
| Open the log | Shows what DeskStamp has been doing |
| Lingua / Language | Switches language, remembered for next time |
| Start with Windows | Runs DeskStamp at login |
| Quit | Closes it |

## Language

DeskStamp starts in the language of your Windows installation if a translation
exists, English otherwise, and you can change it from the menu at any time.

**To add a language**, copy `lang/en.txt`, name it with the two-letter code of
your language (`fr.txt`, `de.txt`, …) and translate only the text to the right
of the equals sign. It appears in the menu on next start — no code to touch.
Pull requests with new translations are welcome.

Day folders are always prefixed with the ISO date (`2026-09-06 …`), so switching
language keeps every existing folder recognised and sorted.

## Files

| File | Purpose |
| --- | --- |
| `DeskStamp.ps1` | The tray program |
| `DeskStamp-Core.ps1` | Shared logic — the rules live here |
| `DeskStamp-DryRun.ps1` | Console version that moves nothing |
| `DeskStamp-Undo.ps1` | Puts recent moves back |
| `Start-DeskStamp.cmd`, `Dry-Run.cmd`, `Undo.cmd` | Launchers |
| `lang/*.txt` | Translations |
| `deskstamp.ico` | The application icon |
| `exclusions.txt` | Your exceptions |
| `deskstamp-log.txt`, `deskstamp-moves.txt`, `deskstamp-snapshot.txt`, `deskstamp-settings.txt` | Generated at runtime, not tracked by Git |

## Requirements

Windows with PowerShell 5.1, included in Windows 10 and 11. The desktop path is
read from Windows itself, so a desktop redirected to OneDrive works too.

## Why PowerShell and not a compiled program

DeskStamp moves files on your computer. You are entitled to check what it
actually does, and a PowerShell script can be read in plain text: open
`DeskStamp-Core.ps1` and verify in ten minutes that it touches nothing else. An
`.exe` would look more professional and tell you less.

## License

MIT — see [LICENSE](LICENSE).
