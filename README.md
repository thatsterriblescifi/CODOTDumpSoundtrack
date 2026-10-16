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
