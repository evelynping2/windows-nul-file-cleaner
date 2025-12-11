# Windows NUL File Cleaner

**Batch delete undeletable NUL, CON, PRN, AUX files on Windows** — A utility to remove reserved device name files that cannot be deleted through normal means.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Windows%2010%20%7C%2011-blue.svg)](https://www.microsoft.com/windows)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

---

## Table of Contents

- [The Problem](#the-problem)
- [Root Cause: AI Tools Think They're on Linux](#root-cause-ai-tools-think-theyre-on-linux)
- [Why These Files Are Undeletable](#why-these-files-are-undeletable)
- [Quick Start](#quick-start)
- [Manual Deletion Methods](#manual-deletion-methods)
- [Known Affected Tools](#known-affected-tools)
- [Prevention](#prevention)
- [Technical Background](#technical-background)
- [References](#references)
- [Contributing](#contributing)
- [License](#license)

---

## The Problem

You encounter a file named `NUL` (or `CON`, `PRN`, `AUX`) that displays one of these errors when you try to delete it:

```
❌ Invalid MS-DOS function
❌ Cannot delete NUL: The system cannot find the file specified
❌ Cannot read from the source file or disk
❌ The file name you specified is not valid or too long
```

**This tool scans your system and removes all such files automatically.**

---

## Root Cause: AI Tools Think They're on Linux

### The Core Issue

Modern AI coding assistants (Claude Code, GitHub Copilot, Cursor, Codeium, etc.) are trained predominantly on **Linux/Unix codebases**. When these tools generate or execute code on Windows, they often assume a Unix-like environment.

### How It Happens

```
┌─────────────────────────────────────────────────────────────────┐
│  AI Assistant generates a shell command:                        │
│                                                                 │
│    some_command > /dev/null 2>&1                               │
│                                                                 │
│  On Linux: Output is discarded (sent to null device)           │
│  On Windows: Creates a literal file named "null" or "nul"      │
└─────────────────────────────────────────────────────────────────┘
```

### Real-World Example

A NUL file was found containing:
```
/usr/bin/bash: line 1: magick: command not found
```

**What happened:** An AI tool executed a script that:
1. Tried to run ImageMagick (`magick` command)
2. Attempted to redirect stderr to `/dev/null` (Linux-style)
3. Windows interpreted this as "create a file named NUL"
4. The error message was written to this newly created file

### The Environment Mismatch

| Aspect | Linux/macOS | Windows |
|--------|-------------|---------|
| Null device | `/dev/null` | `NUL` (device, not file) |
| Path separator | `/` | `\` |
| Shell | bash/zsh | cmd/PowerShell |
| Case sensitivity | Yes | No |

AI tools trained on Unix conventions don't always account for these differences, especially when:
- Running in hybrid environments (WSL, Git Bash, MSYS2)
- Executing cross-platform npm/pip/cargo scripts
- Using containerized or virtualized build tools

---

## Why These Files Are Undeletable

### Reserved Device Names (MS-DOS Legacy)

Windows reserves these names for hardware devices, inherited from MS-DOS (1981):

| Device | Original Purpose | Still Reserved |
|--------|------------------|----------------|
| `CON` | Console (keyboard/screen) | ✅ |
| `PRN` | Default printer | ✅ |
| `AUX` | Auxiliary device (COM1) | ✅ |
| `NUL` | Null device (bit bucket) | ✅ |
| `COM1-COM9` | Serial ports | ✅ |
| `LPT1-LPT9` | Parallel ports | ✅ |

### The Conflict

When you have a **file** named `NUL`:
1. You try to delete it: `del NUL`
2. Windows sees "NUL" and thinks you mean the **NUL device**
3. Windows tries to delete a hardware device (impossible)
4. Error: "Invalid MS-DOS function"

**The file exists, but Windows can't "see" it as a file.**

### The Solution: Extended Path Syntax

The `\\?\` or `\\.\` prefix tells Windows:
> "Treat this path literally. Don't interpret reserved names."

```cmd
del "\\?\C:\Users\You\Desktop\NUL"
```

This bypasses the legacy name resolution and accesses the file directly.

---

## Quick Start

### Option 1: Download and Run

1. Download [`NUL_Cleaner.bat`](./NUL_Cleaner.bat)
2. Double-click to run
3. Enter path to scan (or press Enter for your user folder)
4. Wait for completion

### Option 2: Clone Repository

```bash
git clone https://github.com/SteppeEcho/windows-nul-file-cleaner.git
cd windows-nul-file-cleaner
.\NUL_Cleaner.bat
```

### Administrator Mode

For system directories or permission-denied errors:
1. Right-click `NUL_Cleaner.bat`
2. Select **"Run as administrator"**

---

## Manual Deletion Methods

### Method 1: Command Prompt (Recommended)

```cmd
del "\\?\C:\full\path\to\NUL"
```

### Method 2: Git Bash

If you have Git for Windows:
```bash
cd /c/path/to/folder
rm nul
```

Git Bash uses MSYS2/MinGW which follows POSIX semantics and treats `nul` as an ordinary filename.

### Method 3: PowerShell

```powershell
Remove-Item -LiteralPath "\\?\C:\full\path\to\NUL" -Force
```

### Method 4: WSL (Windows Subsystem for Linux)

```bash
cd /mnt/c/path/to/folder
rm nul
```

---

## Known Affected Tools

### AI Coding Assistants

| Tool | Issue | Status |
|------|-------|--------|
| **Claude Code** | [#4928](https://github.com/anthropics/claude-code/issues/4928) | Reported |
| GitHub Copilot | Shell command generation | Known issue |
| Cursor | Inherited from base models | Known issue |
| Codeium | Cross-platform script execution | Known issue |

### Development Tools

| Tool | Issue |
|------|-------|
| **OCaml Dune** | [#5485](https://github.com/ocaml/dune/issues/5485) |
| **.NET Runtime** | [#62943](https://github.com/dotnet/runtime/issues/62943) |
| **Tutanota** | [#2063](https://github.com/tutao/tutanota/issues/2063) |
| npm packages | Various build scripts |
| Python pip | Setup scripts with shell commands |

---

## Prevention

### For AI Tool Users

1. **Review generated shell commands** before execution
2. **Replace Unix null redirections:**
   ```diff
   - command > /dev/null 2>&1
   + command > NUL 2>&1
   ```
3. **Use WSL for Unix-native workflows** — keeps Linux and Windows filesystems separate
4. **Configure your AI assistant** to specify Windows as target OS

### For Developers Writing Cross-Platform Scripts

```bash
# Detect OS and use appropriate null device
if [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "win32" ]]; then
    NULL_DEV="NUL"
else
    NULL_DEV="/dev/null"
fi

some_command > "$NULL_DEV" 2>&1
```

### For Node.js/npm Scripts

```javascript
const os = require('os');
const nullDevice = os.platform() === 'win32' ? 'NUL' : '/dev/null';
```

---

## Technical Background

### Why Does This Still Exist in 2025?

Microsoft maintains backward compatibility with software written for MS-DOS (1981) and Windows 3.x (1990). Removing reserved device names would break:

- Legacy enterprise software
- Old batch scripts still in production
- Certain hardware drivers

### The Extended Path Prefix

| Prefix | Purpose |
|--------|---------|
| `\\?\` | Extended-length path (bypasses MAX_PATH, disables name parsing) |
| `\\.\` | Device namespace access |

Both prefixes disable the "friendly name" resolution that causes the conflict.

### File System Perspective

At the NTFS level, `NUL` is a perfectly valid filename. The restriction exists only in the Windows API layer (kernel32.dll) for backward compatibility.

---

## References

### Official Documentation
- [Microsoft: Naming Files, Paths, and Namespaces](https://learn.microsoft.com/en-us/windows/win32/fileio/naming-a-file)
- [Microsoft Q&A: Can't delete NUL file (solved)](https://learn.microsoft.com/en-us/answers/questions/2642852/cant-delete-nul-file-(solved))

### Community Solutions
- [Stack Overflow: Delete a file named "NUL" on Windows](https://stackoverflow.com/questions/17883481/delete-a-file-named-nul-on-windows)
- [Lucas' Blog: Delete Stubborn nul File on Windows](https://blog.lucaslifes.com/p/delete-stubborn-nul-file-on-windows/)
- [Tutorialpedia: Delete a File Named NUL on Windows](https://www.tutorialpedia.org/blog/delete-a-file-named-nul-on-windows/)
- [ayllon.github.io: Windows 11 and NUL](https://ayllon.github.io/notes/2025/03/28/nul)

### Related Bug Reports
- [anthropics/claude-code#4928](https://github.com/anthropics/claude-code/issues/4928) — Claude Code creating NUL files
- [dotnet/runtime#62943](https://github.com/dotnet/runtime/issues/62943) — .NET reserved filename handling
- [ocaml/dune#5485](https://github.com/ocaml/dune/issues/5485) — Dune cannot delete NUL files
- [tutao/tutanota#2063](https://github.com/tutao/tutanota/issues/2063) — Reserved file names on Windows

---

## Contributing

Contributions are welcome! Here's how you can help:

1. **Report affected tools** — Found another tool creating NUL files? Open an issue
2. **Improve the script** — Add support for more edge cases
3. **Translations** — Help translate documentation
4. **Spread the word** — Star the repo and share with others facing this issue

### Development

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/windows-nul-file-cleaner.git

# Create feature branch
git checkout -b feature/your-improvement

# Make changes and commit
git commit -am "Add: your improvement"

# Push and create PR
git push origin feature/your-improvement
```

---

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- Microsoft Q&A community for documenting the `\\?\` solution
- [Lucas' Blog](https://blog.lucaslifes.com/) for the Git Bash method
- Everyone who reported issues in the affected projects

---

<p align="center">
  <b>If this tool saved you time, consider giving it a ⭐</b><br>
  It helps others discover this solution!
</p>

---

**Keywords:** windows nul file delete, cannot delete nul file windows, invalid ms-dos function, remove con prn aux files, reserved device name windows, undeletable file windows 10 11, ai code assistant nul bug, claude code nul file, github copilot windows, cross-platform script windows error, del nul file cmd, powershell delete nul
