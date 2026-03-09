# Batch Serien Sortierer V7

PowerShell-Tool zum automatischen Sortieren, Umbenennen und Einsortieren von Serien-, Anime- und Filmdateien für Medienbibliotheken.

Das Script analysiert Videodateien in einem gewählten Quellordner und organisiert sie automatisch in eine saubere Zielstruktur, geeignet für Plex, Jellyfin, Emby oder allgemeine Medienarchive.



## Zweck

Das Script ist dafür gedacht, unsortierte oder uneinheitlich benannte Videodateien aus einem Download- oder Sammelordner automatisiert in eine feste Medienstruktur zu überführen.

Es übernimmt dabei unter anderem:

- Erkennung von Episoden und Staffeln
- Unterscheidung zwischen Serien, Anime und Filmen
- Duplikatbewertung nach Qualitätslogik
- Umbenennung in ein einheitliches Format
- Verschieben in die passende Bibliothek
- Hardlink-Erzeugung bei Multi-Episoden-Dateien
- Prüfung auf fehlende Episoden innerhalb einer Staffel
- Smart Matching auf bestehende Serienordner



## Zielstruktur

Das Script arbeitet mit festen Zielordnern für Medien.

Beispiel:


Z:\Media
├── Series
│   └── Serienname
│       └── S01
│           └── Serienname - S01E01.mkv
├── Anime
│   └── Titel
│       └── S01
│           └── Titel - S01E01.mkv
└── Movies
    └── Filmname.mkv


Die Zielpfade werden direkt im Script definiert und müssen zu deiner Umgebung passen.



## Voraussetzungen

- Windows
- PowerShell 5 oder höher
- Schreibrechte auf Quell- und Zielordner
- Zielordner für Medienbibliothek vorhanden oder durch das Script erstellbar
- Videodateien mit sinnvollen Dateinamen
- anlegen der Pfade im Script ***


## Unterstützte Dateiformate

Das Script verarbeitet folgende Videodateien:


.mp4
.mkv
.avi
.mov
.wmv
.m4v




## Ablauf

### 1. Script starten

Das Script wird direkt in PowerShell gestartet.

Beispiel:


.\rename_episode V7.ps1


### 2. Quellordner auswählen

Nach dem Start öffnet sich ein Explorer-Auswahldialog.  
Dort wählst du den Ordner aus, in dem sich die unsortierten Videodateien befinden.

Das Script durchsucht diesen Ordner rekursiv.

### 3. Analyse der Dateien

Das Script versucht aus den Dateinamen zu erkennen:

- Serienname
- Staffel
- Episode
- Multi-Episode
- Teil-Episoden
- Qualitätsmerkmale
- mögliche Duplikate

### 4. Vorschau

Es werden Vorschauen angezeigt, damit du sehen kannst:

- was erkannt wurde
- welche Duplikate vorhanden sind
- welche Datei als beste Version ausgewählt wurde

### 5. Zielzuordnung

Dateien werden je nach Einordnung verarbeitet als:

- Series
- Anime
- Movies

### 6. Verschieben und Umbenennen

Danach werden die Dateien in die Zielstruktur verschoben und passend umbenannt.



## Unterstützte Episodenmuster

Das Script erkennt unter anderem folgende Schreibweisen:


S01E01
S01E01-E03
S01E01_E03
S01E01E02


Beispiele:


Show.Name.S01E01.mkv
Show.Name.S01E01-E03.mkv
Anime.S01E11E12.mkv


## Multi-Episoden-Unterstützung

Wenn eine Datei mehrere Episoden enthält, verarbeitet das Script diese korrekt.

Beispiel:


Show.S01E01E02.mkv


kann intern als zwei Episoden behandelt werden.

Je nach Logik wird:

- eine Hauptdatei verwendet
- für zusätzliche Episoden ein Hardlink erstellt
- bei Bedarf auf Kopieren zurückgefallen



## Hardlink-Verhalten

Für Multi-Episode-Dateien versucht das Script Hardlinks zu erstellen.

Vorteil:

- kein doppelter Speicherverbrauch
- mehrere Episoden können auf dieselbe Quelldatei zeigen

Falls Hardlinks nicht möglich sind, wird automatisch ein Fallback verwendet.



## Teil-Episoden-Erkennung

Das Script erkennt auch Teilfolgen, zum Beispiel:


Part 1
Part.1
Teil 1
Teil.2


Beispiel:


Show.S01E10.Part.1.mkv


wird passend als Teilfolge behandelt.



## Qualitätsbewertung und Duplikatlogik

Wenn mehrere Versionen derselben Episode existieren, versucht das Script die beste Datei auszuwählen.

### Serien

Priorität typischerweise:

1. Deutsch
2. REPACK
3. größere Datei

### Anime

Priorität typischerweise:

1. Subbed
2. GerSub
3. German
4. REPACK
5. größere Datei

### Filme

Priorität typischerweise:

1. größere Datei
2. REPACK
3. Deutsch

SUB-Versionen werden bei Filmen bevorzugt nicht verwendet.



## Vorschau-System

Das Script zeigt verschiedene Zustände der Analyse.

### Vorschau 1

Rohansicht aller erkannten Dateien inklusive möglicher Duplikate.

### Vorschau 2

Bereinigte Endauswahl nach Filterung und Qualitätsbewertung.

Dadurch kannst du nachvollziehen, warum bestimmte Dateien ausgewählt oder verworfen wurden.


## Vollständigkeitsprüfung pro Staffel

Nach der Analyse kann das Script erkennen, ob innerhalb einer Staffel Episoden fehlen.

Beispiel:


S02 nicht komplett
Fehlt: S02E07


Specials wie `S00` werden dabei separat behandelt bzw. ignoriert.

Das hilft, unvollständige Staffeln schnell zu erkennen.



## Smart Folder Matching

V7 enthält eine intelligentere Ordnerzuordnung.

Dabei werden Unterschiede in Schreibweisen toleriert, zum Beispiel:

- Leerzeichen
- Unterstriche
- Punkte
- Bindestriche
- Groß- und Kleinschreibung

Beispiel:


Dead Account
Dead_Account
dead.account


Diese Namen können als gleich erkannt werden.



## Fuzzy Matching

Wenn kein exakter Zielordner gefunden wird, sucht das Script nach ähnlichen Ordnernamen.

Beispiel:


Erkannt: Dead Account

Gefundene Ordner:
[1] Dead_Account
[2] Death_Account_enen_pa_ora
[0] Neuer Ordner


Dadurch kann der Benutzer entscheiden, ob eine Datei in einen bestehenden Ordner einsortiert werden soll oder ob ein neuer Ordner erstellt wird.


## Fehlerverhalten

Das Script ist darauf ausgelegt, bei problematischen Vorgängen nicht still falsche Ergebnisse zu produzieren.

Typische Fehlerquellen:

- ungültige Pfade
- fehlende Schreibrechte
- Umbenennungsfehler
- Probleme mit Hardlinks
- unerwartete Dateinamen

Bei kritischen Fehlern wird der Vorgang abgebrochen oder sichtbar gemeldet.



## Wichtige Pfade im Script

Vor produktiver Nutzung sollten die Zielpfade im Script geprüft werden.

Typisch sind Bibliothekspfade wie:


Z:\Media\Series
Z:\Media\Anime
Z:\Media\Movies


Wenn dein System andere Laufwerke oder Ordner nutzt, musst du diese Pfade im Script anpassen.

Ebenfalls prüfen:

- Zielbasisordner
- Serienordner
- Animeordner
- Filmordner
- eventuelle temporäre Arbeitsverzeichnisse



## Empfohlene Nutzung

Empfohlene Reihenfolge:

1. Script starten
2. Quellordner auswählen
3. Erkennung und Vorschau prüfen
4. Zielzuordnung kontrollieren
5. Verschiebevorgang ausführen
6. Ergebnis in der Medienbibliothek prüfen

Gerade bei neuen oder ungewöhnlichen Dateinamen sollte man die ersten Durchläufe bewusst kontrollieren.



## Typische Einsatzszenarien

- unsortierte Anime-Downloads
- Serienordner mit gemischten Dateinamen
- Dublettenbereinigung
- Umstellung auf Plex-/Jellyfin-kompatible Struktur
- Nachsortierung bestehender Downloadordner



## Dateiname des Scripts

Aktueller Scriptname:


rename_episode V7.ps1


## Version

V7

Wichtige Erweiterungen in dieser Version:

- Smart Folder Matching
- Fuzzy Matching
- bessere Multi-Episoden-Behandlung
- Qualitätsfilterung
- Staffel-Vollständigkeitsprüfung

---

## Autor

Logi