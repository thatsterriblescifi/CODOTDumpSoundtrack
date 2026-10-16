###############################################################################
#
#  Call of Duty Original Trilogy Backpack Orchestra Remover
#
###############################################################################
#
# Supported games (2007-2011)
#   Call of Duty 4: Modern Warfare (2007)
#   Call of Duty Modern Warfare 2 (2009)
#   Call of Duty Modern Warfare 3 (2011)
#
# Version
#   0.2.0-review
#
# Date
#   2026-10-13
#
# Author
#   rev. Jack Dobson ope machinae Copilot
#
# Purpose
#   Inventory soundtrack resources in IWD archives or, when -r
#   is supplied, replace selected MP3/WAV resources with valid silent audio.
#   Resource paths and filenames remain present so the game can still resolve
#   the resources. Menu, opening, credits, and radio tracks are kept by the
#   filename rules below.
#   The report is saved as backpack_orchestra.txt in the current directory;
#   inventory mode also prints the completed report to the console.
#   CODOTDumpSoundtrack.log is overwritten each run and records console output
#   plus run metrics.
#
# WARNING
#   Replacement mode modifies game archives. Steam can restore original files:
#   Steam -> Library -> game -> Properties -> Installed Files
#        -> Verify integrity of game files
#
# Usage: .\CODOTDumpSoundtrack-v0.2.0.ps1 <mode> [location]
#   Run without arguments to show this usage information.
#
#   Default path: C:\Program Files (x86)\Steam\steamapps\common
#
#   Modes (choose exactly one):
#   -i scans Call of Duty 4, Modern Warfare 2, and Modern Warfare 3.
#   -r replaces eligible MP3/WAV entries in IWD archives with valid silence.
#
#   Location (optional; choose at most one):
#   -d <drive> selects the drive for the standard Steam path (default: C:).
#   -p <path> supplies the full steamapps\common path instead of -d.
#
#   Examples:
#     .\CODOTDumpSoundtrack-v0.2.0.ps1 -i
#     .\CODOTDumpSoundtrack-v0.2.0.ps1 -r -d T
#     .\CODOTDumpSoundtrack-v0.2.0.ps1 -i -p 'D:\Games\Steam\steamapps\common'
#
#   FFmpeg must be available on PATH for replacement mode.
#   Download: https://www.gyan.dev/ffmpeg/
#   CODOTDumpSoundtrack.log in the current directory mirrors screen output and
#   includes run metrics; it is overwritten each run.
#
###############################################################################

function Show-Usage {
    @'
# Call of Duty Original Trilogy Backpack Orchestra Remover

Supported games (2007-2011):
    Call of Duty 4: Modern Warfare (2007)
    Call of Duty Modern Warfare 2 (2009)
    Call of Duty Modern Warfare 3 (2011)

Version: 0.2.0-review
Date: 2026-10-13
Author: rev. Jack Dobson ope machinae Copilot

Purpose: Inventory soundtrack resources in IWD archives or, with -r, replace
selected MP3/WAV resources with valid silent audio. Resource paths and filenames
remain present. Menu, opening, credits, and radio tracks are kept by filename rules.

Warning: Replacement mode modifies game archives. Steam can restore original files:
    Steam -> Library -> game -> Properties -> Installed Files
             -> Verify integrity of game files

Inventory report: backpack_orchestra.txt in the current directory.
The -i mode prints the completed report after scanning.
Log: CODOTDumpSoundtrack.log in the current directory, overwritten each run.
The log mirrors screen output and includes run metrics.

Usage: .\CODOTDumpSoundtrack-v0.2.0.ps1 <mode> [location]
Run without arguments to display this usage information.

Default path: C:\Program Files (x86)\Steam\steamapps\common

Modes (choose exactly one):
-i  Scan Call of Duty 4, Modern Warfare 2, and Modern Warfare 3.
-r  Replace eligible MP3/WAV entries in their IWD archives with valid silence.

Location (optional; choose at most one):
-d <drive>  Select the drive for the standard Steam path (default: C:).
-p <path>   Supply the full steamapps\common path instead of -d.

Examples:
.\CODOTDumpSoundtrack-v0.2.0.ps1 -i
.\CODOTDumpSoundtrack-v0.2.0.ps1 -r -d T
.\CODOTDumpSoundtrack-v0.2.0.ps1 -i -p 'D:\Games\Steam\steamapps\common'

FFmpeg must be available on PATH for replacement mode.
Download: https://www.gyan.dev/ffmpeg/
'@ | Write-Host
    Write-Host "Log file: $LogFile"
    Write-Host 'Run status: usage displayed; no game scan performed.'
    Stop-RunTranscript
}

$LogFile = Join-Path (Get-Location).Path 'CODOTDumpSoundtrack.log'
$script:TranscriptStarted = $false
Start-Transcript -Path $LogFile -Force -IncludeInvocationHeader | Out-Null
$script:TranscriptStarted = $true

function Stop-RunTranscript {
    if ($script:TranscriptStarted) {
        Stop-Transcript | Out-Null
        $script:TranscriptStarted = $false
    }
}

trap {
    Write-Host "Run terminated: $($_.Exception.Message)"
    Stop-RunTranscript
    throw
}

$InventoryOnly = $false
$ApplyChanges = $false
$DriveSpecified = $false
$PathSpecified = $false
$DriveLetter = 'C'
$CustomSteamRoot = $null

if ($args.Count -eq 0) {
    Show-Usage
    return
}

for ($Index = 0; $Index -lt $args.Count; $Index++) {
    $Argument = [string]$args[$Index]

    if ($Argument -match '^(?i)-i$') {
        $InventoryOnly = $true
    }
    elseif ($Argument -match '^(?i)-r$') {
        $ApplyChanges = $true
    }
    elseif ($Argument -match '^(?i)-d$') {
        if ($Index + 1 -ge $args.Count) {
            Write-Warning "Option '$Argument' requires a drive letter."
            Show-Usage
            return
        }

        $Index++
        $DriveValue = [string]$args[$Index]
        if ($DriveValue -notmatch '^[A-Za-z]:?\\?$') {
            Write-Warning "Invalid drive '$DriveValue'. Specify a drive letter such as C, C:, or C:\\."
            Show-Usage
            return
        }

        $DriveLetter = $DriveValue.Substring(0, 1).ToUpperInvariant()
        $DriveSpecified = $true
    }
    elseif ($Argument -match '^(?i)-p$') {
        if ($Index + 1 -ge $args.Count) {
            Write-Warning "Option '$Argument' requires a path."
            Show-Usage
            return
        }

        $Index++
        $CustomSteamRoot = [string]$args[$Index]
        $PathSpecified = $true
    }
    else {
        Write-Warning "Unknown option '$Argument'."
        Show-Usage
        return
    }
}

if (!$InventoryOnly -and !$ApplyChanges) {
    Write-Warning 'Choose a mode: -i or -r.'
    Show-Usage
    return
}

if ($InventoryOnly -and $ApplyChanges) {
    Write-Warning 'Choose exactly one mode: -i or -r.'
    Show-Usage
    return
}

if ($DriveSpecified -and $PathSpecified) {
    Write-Warning 'Use either -d or -p, not both.'
    Show-Usage
    return
}

$ErrorActionPreference = 'Stop'
$Metrics = [ordered]@{
    GameDirectoriesFound = 0
    GameDirectoriesMissing = 0
    ArchivesFound = 0
    ArchivesScanned = 0
    ArchiveScanErrors = 0
    MusicEntries = 0
    MuteCandidates = 0
    KeptEntries = 0
    SkippedEntries = 0
    ArchivesUpdated = 0
    ArchiveUpdateFailures = 0
    EntriesReplaced = 0
}
$RunTimer = [System.Diagnostics.Stopwatch]::StartNew()
Add-Type -AssemblyName System.IO.Compression.FileSystem

$SteamRoot = if ($PathSpecified) {
    $CustomSteamRoot
}
else {
    "${DriveLetter}:\Program Files (x86)\Steam\steamapps\common"
}
$Games = @(
    'Call of Duty 4',
    'Call of Duty Modern Warfare 2',
    'Call of Duty Modern Warfare 3'
)

$OutputFile = 'backpack_orchestra.txt'
$WorkRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("CODOTDumpSoundtrack_{0}" -f [guid]::NewGuid())
$SilentMp3 = Join-Path $WorkRoot 'silence.mp3'
$SilentWav = Join-Path $WorkRoot 'silence.wav'

function Write-Line {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Text)
    Add-Content -LiteralPath $OutputFile -Value $Text -Encoding UTF8
}

function Invoke-FFmpeg {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [Parameter(Mandatory)][string]$Purpose
    )

    & $script:FFmpegPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "FFmpeg failed while $Purpose (exit code $LASTEXITCODE)."
    }
}

function Test-SilentAudio {
    param([Parameter(Mandatory)][string]$Path)

    # Decode the complete file. A successful decode is a basic container/codec
    # check; the file is generated from FFmpeg's digital-silence source.
    Invoke-FFmpeg -Arguments @(
        '-hide_banner', '-v', 'error', '-i', $Path,
        '-f', 'null', 'NUL'
    ) -Purpose "validating '$Path'"
}

function New-SilentAudioFiles {
    if (!(Test-Path -LiteralPath $script:FFmpegPath)) {
        throw "FFmpeg executable not found: $script:FFmpegPath"
    }

    New-Item -ItemType Directory -Path $script:WorkRoot -Force | Out-Null

    # Short, valid audio files. Track duration is intentionally not preserved.
    Invoke-FFmpeg -Arguments @(
        '-hide_banner', '-loglevel', 'error', '-y',
        '-f', 'lavfi', '-i', 'anullsrc=channel_layout=stereo:sample_rate=44100',
        '-t', '0.25', '-c:a', 'libmp3lame', '-q:a', '9',
        $script:SilentMp3
    ) -Purpose 'creating silent MP3'

    Invoke-FFmpeg -Arguments @(
        '-hide_banner', '-loglevel', 'error', '-y',
        '-f', 'lavfi', '-i', 'anullsrc=channel_layout=stereo:sample_rate=44100',
        '-t', '0.25', '-c:a', 'pcm_s16le', '-ar', '44100', '-ac', '2',
        $script:SilentWav
    ) -Purpose 'creating silent WAV'

    Test-SilentAudio -Path $script:SilentMp3
    Test-SilentAudio -Path $script:SilentWav
}

function Get-MusicAction {
    param([Parameter(Mandatory)][string]$EntryPath)

    $Name = [System.IO.Path]::GetFileName($EntryPath)
    if ([string]::IsNullOrWhiteSpace($Name)) {
        return 'SKIP_DIRECTORY'
    }

    $Extension = [System.IO.Path]::GetExtension($Name).ToLowerInvariant()
    if ($Extension -notin @('.mp3', '.wav')) {
        return 'SKIP_UNSUPPORTED'
    }

    # Keep these categories using the existing prototype's filename heuristic.
    if ($Name -match 'menu' -or
        $Name -match 'opening' -or
        $Name -match 'credit' -or
        $Name -match 'radio') {
        return 'KEEP'
    }

    return 'MUTE'
}

function Update-IwdArchiveWithSilence {
    param(
        [Parameter(Mandatory)][string]$ArchivePath,
        [Parameter(Mandatory)][object[]]$Targets
    )

    $Directory = Split-Path -Parent $ArchivePath
    $TempArchive = Join-Path $Directory ('.{0}.{1}.working' -f (Split-Path -Leaf $ArchivePath), [guid]::NewGuid())
    $Replaced = 0

    try {
        # This is a temporary working copy used to avoid leaving a half-written
        # original archive if an operation fails; it is not a retained backup.
        Copy-Item -LiteralPath $ArchivePath -Destination $TempArchive

        $Zip = [System.IO.Compression.ZipFile]::Open(
            $TempArchive,
            [System.IO.Compression.ZipArchiveMode]::Update
        )
        try {
            foreach ($Target in $Targets) {
                $EntryMatches = @($Zip.Entries | Where-Object {
                    [string]::Equals($_.FullName, $Target.EntryPath, [StringComparison]::OrdinalIgnoreCase)
                })

                if ($EntryMatches.Count -ne 1) {
                    throw "Expected exactly one entry '$($Target.EntryPath)' in '$ArchivePath'; found $($EntryMatches.Count)."
                }

                $OldEntry = $EntryMatches[0]
                $EntryPath = $OldEntry.FullName
                $Extension = [System.IO.Path]::GetExtension($EntryPath).ToLowerInvariant()
                $SilentPath = if ($Extension -eq '.mp3') { $script:SilentMp3 } else { $script:SilentWav }

                $OldEntry.Delete()
                $NewEntry = $Zip.CreateEntry($EntryPath, [System.IO.Compression.CompressionLevel]::Optimal)
                $InputStream = [System.IO.File]::OpenRead($SilentPath)
                try {
                    $OutputStream = $NewEntry.Open()
                    try { $InputStream.CopyTo($OutputStream) }
                    finally { $OutputStream.Dispose() }
                }
                finally { $InputStream.Dispose() }

                $Replaced++
            }
        }
        finally {
            $Zip.Dispose()
        }

        # Re-open the resulting archive and confirm each replacement is present
        # and non-empty before allowing it to replace the original.
        $CheckZip = [System.IO.Compression.ZipFile]::OpenRead($TempArchive)
        try {
            foreach ($Target in $Targets) {
                $Found = @($CheckZip.Entries | Where-Object {
                    [string]::Equals($_.FullName, $Target.EntryPath, [StringComparison]::OrdinalIgnoreCase)
                })
                if ($Found.Count -ne 1 -or $Found[0].Length -le 0) {
                    throw "Post-write validation failed for '$($Target.EntryPath)' in '$ArchivePath'."
                }

                # Read the entry fully to ensure the ZIP member can be decompressed.
                $Stream = $Found[0].Open()
                try {
                    $Buffer = New-Object byte[] 8192
                    while ($Stream.Read($Buffer, 0, $Buffer.Length) -gt 0) { }
                }
                finally { $Stream.Dispose() }
            }
        }
        finally {
            $CheckZip.Dispose()
        }

        Move-Item -LiteralPath $TempArchive -Destination $ArchivePath -Force
        return $Replaced
    }
    finally {
        if (Test-Path -LiteralPath $TempArchive) {
            Remove-Item -LiteralPath $TempArchive -Force -ErrorAction SilentlyContinue
        }
    }
}

# Locate FFmpeg only in replacement mode. Inventory-only mode has no dependency.
$script:FFmpegPath = $null
if ($ApplyChanges) {
    $FFmpegCommand = Get-Command ffmpeg -ErrorAction SilentlyContinue
    if (!$FFmpegCommand) {
        throw 'FFmpeg was not found on PATH. Install FFmpeg or add its bin directory to PATH, then retry.'
    }
    $script:FFmpegPath = $FFmpegCommand.Source
}

if (Test-Path -LiteralPath $OutputFile) {
    Remove-Item -LiteralPath $OutputFile -Force
}

Write-Line '=========================================================='
Write-Line 'MODERN WARFARE ORIGINAL TRILOGY MUSIC INVENTORY'
Write-Line "Generated: $(Get-Date)"
Write-Line "Mode: $(if ($ApplyChanges) { 'REPLACE SELECTED TRACKS WITH SILENCE' } else { 'INVENTORY ONLY' })"
Write-Line 'FORMAT: ACTION|GAME|ARCHIVE|ENTRY|RESULT'
Write-Line '=========================================================='

$Inventory = [System.Collections.Generic.List[object]]::new()

foreach ($Game in $Games) {
    $GamePath = Join-Path $SteamRoot $Game
    Write-Host "`nScanning: $Game"

    Write-Line ''
    Write-Line '=========================================================='
    Write-Line "GAME: $Game"
    Write-Line "PATH: $GamePath"
    Write-Line '=========================================================='

    if (!(Test-Path -LiteralPath $GamePath)) {
        $Metrics.GameDirectoriesMissing++
        Write-Line 'NOT FOUND||||Game directory not found'
        Write-Warning "Game directory not found: $GamePath"
        continue
    }

    $Metrics.GameDirectoriesFound++
    $IWDs = @(Get-ChildItem -LiteralPath $GamePath -Recurse -File -Filter '*.iwd' -ErrorAction SilentlyContinue)
    $Metrics.ArchivesFound += $IWDs.Count
    foreach ($IWD in $IWDs) {
        $Zip = $null
        try {
            $Zip = [System.IO.Compression.ZipFile]::OpenRead($IWD.FullName)
            foreach ($Entry in $Zip.Entries) {
                if ($Entry.FullName -notmatch '^Sound/music/') { continue }

                $Action = Get-MusicAction -EntryPath $Entry.FullName
                $Metrics.MusicEntries++
                switch ($Action) {
                    'MUTE' { $Metrics.MuteCandidates++ }
                    'KEEP' { $Metrics.KeptEntries++ }
                    default { $Metrics.SkippedEntries++ }
                }
                if ($Action -in @('SKIP_DIRECTORY', 'SKIP_UNSUPPORTED')) {
                    $Result = if ($Action -eq 'SKIP_DIRECTORY') { 'Directory entry; not an audio file' } else { 'Unsupported extension; not modified' }
                }
                else {
                    $Result = if ($Action -eq 'KEEP') { 'Preserved by filename rule' } else { 'Identified for silence replacement' }
                }

                $Record = [pscustomobject]@{
                    Action = $Action
                    Game = $Game
                    ArchiveName = $IWD.Name
                    ArchivePath = $IWD.FullName
                    EntryPath = $Entry.FullName
                    Result = $Result
                }
                $Inventory.Add($Record)
                Write-Line ("{0}|{1}|{2}|{3}|{4}" -f $Action, $Game, $IWD.Name, $Entry.FullName, $Result)
            }
            $Metrics.ArchivesScanned++
        }
        catch {
            $Metrics.ArchiveScanErrors++
            Write-Line ("ERROR|{0}|{1}||{2}" -f $Game, $IWD.Name, $_.Exception.Message)
            Write-Warning "Could not scan $($IWD.FullName): $($_.Exception.Message)"
        }
        finally {
            if ($null -ne $Zip) { $Zip.Dispose() }
        }
    }
}

if ($ApplyChanges) {
    try {
        New-SilentAudioFiles

        $Groups = @($Inventory | Where-Object { $_.Action -eq 'MUTE' } | Group-Object -Property ArchivePath)
        foreach ($Group in $Groups) {
            $ArchivePath = $Group.Name
            $Targets = @($Group.Group | ForEach-Object {
                [pscustomobject]@{ EntryPath = $_.EntryPath }
            })

            try {
                $Count = Update-IwdArchiveWithSilence -ArchivePath $ArchivePath -Targets $Targets
                $Metrics.ArchivesUpdated++
                $Metrics.EntriesReplaced += $Count
                foreach ($Record in $Group.Group) {
                    $Record.Result = 'REPLACED WITH VALID SILENCE'
                    Write-Host "  MUTED: $($Record.EntryPath)"
                }
                Write-Host "Updated $ArchivePath ($Count entries)."
            }
            catch {
                $Metrics.ArchiveUpdateFailures++
                foreach ($Record in $Group.Group) {
                    $Record.Result = "FAILED: $($_.Exception.Message)"
                }
                Write-Warning "Archive not replaced: $ArchivePath. $($_.Exception.Message)"
            }
        }

        # Rebuild the report's per-entry rows with their final outcomes.
        $ReportLines = [System.Collections.Generic.List[string]]::new()
        $ReportLines.Add('==========================================================')
        $ReportLines.Add('MODERN WARFARE ORIGINAL TRILOGY MUSIC INVENTORY')
        $ReportLines.Add("Generated: $(Get-Date)")
        $ReportLines.Add('Mode: REPLACE SELECTED TRACKS WITH SILENCE')
        $ReportLines.Add('FORMAT: ACTION|GAME|ARCHIVE|ENTRY|RESULT')
        $ReportLines.Add('==========================================================')
        foreach ($Record in $Inventory) {
            $ReportLines.Add(("{0}|{1}|{2}|{3}|{4}" -f $Record.Action, $Record.Game, $Record.ArchiveName, $Record.EntryPath, $Record.Result))
        }
        Set-Content -LiteralPath $OutputFile -Value $ReportLines -Encoding UTF8
    }
    finally {
        if (Test-Path -LiteralPath $WorkRoot) {
            Remove-Item -LiteralPath $WorkRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Line ''
Write-Line 'END OF REPORT'
$RunTimer.Stop()
Write-Host "`nInventory complete."
if ($ApplyChanges) {
    Write-Host 'Replacement mode finished. Review the result column and any warnings above.'
}
else {
    Write-Host 'Inventory-only mode: no game files were modified.'
    Write-Host 'To replace eligible MP3/WAV entries with silence, run with -r.'
}
Write-Host "Output written to: $OutputFile"
Write-Host "Log written to: $LogFile"
Write-Host "`nRun metrics:"
Write-Host ("Game directories: {0} found, {1} missing" -f $Metrics.GameDirectoriesFound, $Metrics.GameDirectoriesMissing)
Write-Host ("Archives: {0} found, {1} scanned, {2} scan errors" -f $Metrics.ArchivesFound, $Metrics.ArchivesScanned, $Metrics.ArchiveScanErrors)
Write-Host ("Music entries: {0} total, {1} mute candidates, {2} kept, {3} skipped" -f $Metrics.MusicEntries, $Metrics.MuteCandidates, $Metrics.KeptEntries, $Metrics.SkippedEntries)
Write-Host ("Archive updates: {0} successful, {1} failed; {2} entries replaced" -f $Metrics.ArchivesUpdated, $Metrics.ArchiveUpdateFailures, $Metrics.EntriesReplaced)
Write-Host ("Elapsed: {0:N2} seconds; report size: {1} bytes" -f $RunTimer.Elapsed.TotalSeconds, (Get-Item -LiteralPath $OutputFile).Length)
if ($InventoryOnly) {
    Write-Host "`nInventory report contents:"
    Get-Content -LiteralPath $OutputFile
}
Stop-RunTranscript
