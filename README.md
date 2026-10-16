# Call of Duty Original Trilogy Soundtrack Tool

A PowerShell script to inventory soundtrack files in the IWD archives for the
original *Call of Duty: Modern Warfare* trilogy, or replace eligible music
tracks with valid silent audio while leaving the resource paths in place.

Supported games:

- *Call of Duty 4: Modern Warfare* (2007)
- *Call of Duty: Modern Warfare 2* (2009)
- *Call of Duty: Modern Warfare 3* (2011)

Menu, opening, credits, and radio tracks are kept according to the script's
filename rules.

## Requirements

- Windows with PowerShell
- Installed game folders under the standard Steam `steamapps\common` directory,
  or the path to that directory supplied with `-p`
- FFmpeg on `PATH` for replacement mode (`-r` only)

## Usage

Open PowerShell in the folder containing the script and run:

```powershell
.\CODOTDumpSoundtrack-v0.2.0.ps1 -i
```

Choose exactly one mode:

| Option | Description |
| --- | --- |
| `-i` | Inventory soundtrack resources in the three games. |
| `-r` | Replace eligible MP3/WAV resources in the games' IWD archives with valid silence. |

The script uses `C:\Program Files (x86)\Steam\steamapps\common` by default.
Choose at most one optional location:

| Option | Description |
| --- | --- |
| `-d <drive>` | Use the standard Steam path on another drive, such as `-d T`. |
| `-p <path>` | Supply the full `steamapps\common` path. |

Examples:

```powershell
# Inventory the default Steam installation
.\CODOTDumpSoundtrack-v0.2.0.ps1 -i

# Replace eligible tracks in a Steam installation on T:
.\CODOTDumpSoundtrack-v0.2.0.ps1 -r -d T

# Inventory games in a custom Steam library
.\CODOTDumpSoundtrack-v0.2.0.ps1 -i -p 'D:\Games\Steam\steamapps\common'
```

For replacement mode, install FFmpeg and make sure `ffmpeg` is available on
`PATH`. See [FFmpeg download options](https://ffmpeg.org/download.html).

## Output

Each run writes `backpack_orchestra.txt` (the inventory or replacement report)
and overwrites `CODOTDumpSoundtrack.log` in the current directory. The log is a
PowerShell transcript and may include your Windows username and computer name;
review it before sharing. These generated files are excluded from this Git
repository.

## Important

Replacement mode modifies game archives. Back up your game files before using
it. Steam can restore original files through **Library → game → Properties →
Installed Files → Verify integrity of game files**.

This is an independent community tool and is not affiliated with or endorsed by
Activision or the Call of Duty developers or publishers.

## License

No license has been selected yet. Until one is added, the code is publicly
visible on GitHub, but that does not grant permission to reuse, modify, or
redistribute it.
