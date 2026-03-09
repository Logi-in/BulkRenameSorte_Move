# ==============================================================
# Batch Serien Sortierer V7
# ==============================================================
try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
Add-Type -AssemblyName System.Windows.Forms

Write-Host "=== Batch Serien Sortierer V7 ===" -ForegroundColor Cyan
Write-Host ""

# ==========================================
# 1 Explorer Auswahl
# ==========================================

$dialog = New-Object System.Windows.Forms.FolderBrowserDialog
$dialog.Description = "Download- oder Video-Ordner auswählen"
$dialog.ShowNewFolderButton = $false

if ($dialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "Abgebrochen."
    pause
    exit
}

$sourceFolder = $dialog.SelectedPath

Write-Host "Gewählter Ordner:" -ForegroundColor Yellow
Write-Host "  $sourceFolder"
Write-Host ""

# ==========================================
# Zielbasen
# ==========================================

$seriesRoot = "PATH-FESTLEGEN"
$animeRoot  = "PATH-FESTLEGEN"
$moviesRoot = "PATH-FESTLEGEN"

foreach($root in @($seriesRoot,$animeRoot,$moviesRoot)){
    if (!(Test-Path $root)) {
        Write-Host "Zielbasis existiert nicht: $root" -ForegroundColor Red
        pause
        exit
    }
}

# ==========================================
# Video Extensions
# ==========================================

$videoExt = @(".mp4",".mkv",".avi",".mov",".wmv",".m4v")

# ==========================================
# Release Marker
# ==========================================

$germanTags = @("german","dubbed","gerdub","ger","deutsch",".dl."," dl ")
$subTags    = @("sub","subbed","subs","gersub","jpn","japanese","eng sub","en sub","subtitles","multi subs","subbed")

function Is-German($name){
    $lower=$name.ToLower()
    foreach($t in $germanTags){
        if($lower -like "*$t*"){return $true}
    }
    return $false
}

function Has-Repack($name){
    return ($name.ToLower() -like "*repack*")
}

function Is-Subbed($name){
    $lower=$name.ToLower()
    foreach($t in $subTags){
        if($lower -like "*$t*"){return $true}
    }
    return $false
}

function Is-GerSub($name){
    if((Is-German $name) -and (Is-Subbed $name)){return $true}
    return $false
}

function Is-PureSub($name){
    if((Is-Subbed $name) -and !(Is-German $name)){return $true}
    return $false
}

# ==========================================
# Episode Tag Helper
# ==========================================

function Format-EpisodeTag($season,$ep){
    return ("S{0:D2}E{1:D2}" -f [int]$season,[int]$ep)
}

function Build-MultiTag($season,$from,$to){

    $tags=@()

    for($e=[int]$from;$e -le [int]$to;$e++){
        $tags+=(Format-EpisodeTag $season $e)
    }

    return ($tags -join "+")
}

# ==========================================
# Dateien laden
# ==========================================

$files = Get-ChildItem $sourceFolder -Recurse -File |
         Where-Object { $videoExt -contains $_.Extension.ToLower() }

if($files.Count -eq 0){
    Write-Host "Keine Videodateien gefunden!" -ForegroundColor Red
    pause
    exit
}

# ==========================================
# Serienordner Name
# ==========================================

function Get-SeriesFolderName($seriesName){
    return ($seriesName -replace "\s+","_").Trim()
}

# ==========================================
# SMART FOLDER MATCH ENGINE (NEU V7)
# ==========================================

function Normalize-SeriesKey($name){

    if([string]::IsNullOrWhiteSpace($name)){ return "" }

    $k=$name.ToLowerInvariant()
    $k=$k -replace "[\s_\-\.]+",""
    $k=$k -replace "[^a-z0-9äöüß]",""

    return $k
}

function Get-SeriesTokens($name){

    $clean=$name.ToLower()
    $clean=$clean -replace "[_\-\.]"," "
    $clean=$clean -replace "[^a-z0-9äöüß ]",""

    return $clean.Split(" ",[System.StringSplitOptions]::RemoveEmptyEntries)
}

$seriesFolderCache=@{}

function Resolve-SeriesFolderSmart($root,$seriesName){

    if($seriesFolderCache.ContainsKey($seriesName)){
        return $seriesFolderCache[$seriesName]
    }

    $normalizedWanted=Normalize-SeriesKey $seriesName

    $dirs=Get-ChildItem $root -Directory -ErrorAction SilentlyContinue

    foreach($d in $dirs){
        if((Normalize-SeriesKey $d.Name) -eq $normalizedWanted){
            $seriesFolderCache[$seriesName]=$d.FullName
            return $d.FullName
        }
    }

    $wantedTokens=Get-SeriesTokens $seriesName
    $candidates=@()

    foreach($d in $dirs){

        $tokens=Get-SeriesTokens $d.Name
        $score=0

        foreach($t in $wantedTokens){
            if($tokens -contains $t){$score++}
        }

        if($score -gt 0){
            $candidates+=[PSCustomObject]@{
                Folder=$d.FullName
                Name=$d.Name
                Score=$score
            }
        }
    }

    if($candidates.Count -gt 0){

        $candidates=$candidates | Sort Score -Descending

        Write-Host ""
        Write-Host "Serie erkannt: $seriesName" -ForegroundColor Yellow
        Write-Host "Ähnliche vorhandene Ordner:" -ForegroundColor Cyan

        $i=1
        foreach($c in $candidates){
            Write-Host "[$i] $($c.Name)"
            $i++
        }

        Write-Host "[0] Neuer Ordner erstellen"
        Write-Host ""

        while($true){

            $choice=Read-Host "Auswahl"

            if($choice -eq "0"){
                $newPath=Join-Path $root (Get-SeriesFolderName $seriesName)
                $seriesFolderCache[$seriesName]=$newPath
                return $newPath
            }

            if($choice -match "^\d+$"){
                $index=[int]$choice
                if($index -ge 1 -and $index -le $candidates.Count){
                    $selected=$candidates[$index-1].Folder
                    $seriesFolderCache[$seriesName]=$selected
                    return $selected
                }
            }
        }
    }

    $fallback=Join-Path $root (Get-SeriesFolderName $seriesName)
    $seriesFolderCache[$seriesName]=$fallback
    return $fallback
}

# ==========================================
# PARSER
# ==========================================

function Parse-EpisodeName($filename){

    $base=[System.IO.Path]::GetFileNameWithoutExtension($filename)

    $part=$null
    if($base -match "(?i)(Teil|Part)[\.\s_-]*(\d+)"){
        $part=[int]$matches[2]
    }

    $mMulti=[regex]::Match($base,"(?i)S(\d{1,2})E(\d{1,2})[-_]E(\d{1,2})")

    if($mMulti.Success){

        $season=[int]$mMulti.Groups[1].Value
        $startEp=[int]$mMulti.Groups[2].Value
        $endEp=[int]$mMulti.Groups[3].Value

        if($endEp -gt $startEp){

            $seriesPart=$base.Substring(0,$mMulti.Index)
            $seriesPart=$seriesPart -replace "[^a-zA-Z0-9äöüÄÖÜß]+"," "
            $seriesPart=$seriesPart.Trim()

            return @{
                Series=$seriesPart
                Season=$season
                Episode=$startEp
                Part=$part
                MultiStart=$startEp
                MultiEnd=$endEp
                Success=$true
            }
        }
    }

    $m=[regex]::Match($base,"(?i)S(\d{1,2})E(\d{1,2})")

    if($m.Success){

        $season=[int]$m.Groups[1].Value
        $episode=[int]$m.Groups[2].Value

        $seriesPart=$base.Substring(0,$m.Index)
        $seriesPart=$seriesPart -replace "[^a-zA-Z0-9äöüÄÖÜß]+"," "
        $seriesPart=$seriesPart.Trim()

        return @{
            Series=$seriesPart
            Season=$season
            Episode=$episode
            Part=$part
            MultiStart=$null
            MultiEnd=$null
            Success=$true
        }
    }

    return @{Success=$false}
}

# ==========================================
# Analyse
# ==========================================

$items=@()
$ignored=@()

foreach($file in $files){

    $p=Parse-EpisodeName $file.Name

    if($p.Success){

        $items+=[PSCustomObject]@{
            File=$file
            Series=$p.Series
            Season=$p.Season
            Episode=$p.Episode
            Part=$p.Part
            MultiFrom=$p.MultiStart
            MultiTo=$p.MultiEnd
            IsGerman=(Is-German $file.Name)
            IsRepack=(Has-Repack $file.Name)
            IsSubbed=(Is-Subbed $file.Name)
        }
    }
    else{
        $ignored+=$file
    }
}

if($items.Count -eq 0){

    Write-Host "Keine passenden Episoden (SxxExx) gefunden!" -ForegroundColor Red
    Write-Host "Ignoriert: $($ignored.Count)"
    pause
    exit
}

# ==========================================
# SHOW ZUORDNUNG
# ==========================================

$uniqueShows=$items | Select-Object -ExpandProperty Series -Unique | Sort-Object
$showTypeMap=@{}
$showRootMap=@{}

Write-Host ""
Write-Host "=== SHOW ZUORDNUNG ===" -ForegroundColor Cyan

foreach($show in $uniqueShows){

    Write-Host ""
    Write-Host "Show: $show" -ForegroundColor Yellow
    Write-Host "1 = Serie"
    Write-Host "2 = Anime"
    Write-Host "3 = Movies"

    $choice=$null

    while($choice -notin @("1","2","3")){
        $choice=Read-Host "Eingabe"
    }

    switch($choice){
        "1"{$showTypeMap[$show]="Serie";$showRootMap[$show]=$seriesRoot}
        "2"{$showTypeMap[$show]="Anime";$showRootMap[$show]=$animeRoot}
        "3"{$showTypeMap[$show]="Movies";$showRootMap[$show]=$moviesRoot}
    }
}

# ==========================================
# MOVE
# ==========================================

$total=$items.Count
$index=0

foreach($i in $items){

    $index++

    Write-Progress -Activity "Serien werden einsortiert..." `
                   -Status "[$index/$total] $($i.File.Name)" `
                   -PercentComplete (($index/$total)*100)

    $suffix=""
    if($i.Part){$suffix="_Teil$($i.Part)"}

    $targetRoot=$showRootMap[$i.Series]

    # SMART MATCH
    $seriesFolder=Resolve-SeriesFolderSmart $targetRoot $i.Series

    $seasonFolder=Join-Path $seriesFolder ("S"+$i.Season.ToString("00"))

    if(!(Test-Path $seasonFolder)){
        New-Item -ItemType Directory -Path $seasonFolder | Out-Null
    }

    $newName="$($i.Series) - S$($i.Season.ToString("00"))E$($i.Episode.ToString("00"))$suffix$($i.File.Extension)"

    $targetPath=Join-Path $seasonFolder $newName

    if(Test-Path $targetPath){continue}

    Move-Item -LiteralPath $i.File.FullName -Destination $targetPath
}

Write-Progress -Activity "Serien werden einsortiert..." -Completed

Write-Host ""
Write-Host "FERTIG." -ForegroundColor Green
pause
