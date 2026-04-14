# Windows Configuration

This directory contains documentation and scripts for Windows machines.

Since Nix doesn't run natively on Windows, this directory stores:
- Manual setup instructions
- PowerShell scripts for configuration
- Links to Windows-specific tools

## Setup Steps

1. Install Windows Package Manager (winget)
2. Install Windows Terminal
3. Install development tools via winget
4. Configure WSL2 if needed (can use NixOS in WSL)

## Tools to Install

```powershell
# Terminal and shell
winget install Microsoft.WindowsTerminal

# Development
winget install Git.Git
winget install Microsoft.VisualStudioCode

# Browsers
winget install Mozilla.Firefox
winget install Google.Chrome
```

## WSL2 with NixOS

For a Nix-managed environment on Windows, consider running NixOS in WSL2.
See: https://github.com/nix-community/NixOS-WSL
