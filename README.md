# Nix Configuration

Personal Nix configuration for macOS and NixOS machines.

## Setup

### Prerequisites

1. **Install Nix** (with flakes enabled):
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
   ```

2. **Clone this repository**:
   ```bash
   git clone https://github.com/yourusername/nix-config.git ~/projects/nix-config
   cd ~/projects/nix-config
   ```

### First-time Installation

**macOS:**
```bash
nix run nix-darwin -- switch --flake .#macbook-pro
```

**NixOS:**
```bash
sudo nixos-rebuild switch --flake .#hostname
```

### Rebuilding After Changes

```bash
rebuild  # alias available after first install
```

## Quick Start

### Adding Packages

| Package Type | File to Edit | Example |
|-------------|--------------|---------|
| CLI tool (all machines) | `profiles/base.nix` | `environment.systemPackages = [ pkgs.htop ];` |
| CLI tool (workstations only) | `profiles/workstation.nix` | `environment.systemPackages = [ pkgs.lazygit ];` |
| CLI tool (servers only) | `profiles/server.nix` | `environment.systemPackages = [ pkgs.tmux ];` |
| macOS GUI app (Homebrew) | `modules/darwin/homebrew.nix` | `casks = [ "discord" ];` |
| Machine-specific package | `hosts/darwin/<machine>/default.nix` | Add to imports or packages |

### Adding Shell Aliases

| Alias Type | File to Edit |
|-----------|--------------|
| Cross-platform | `modules/home/shell/default.nix` |
| macOS only | `modules/home/shell/darwin.nix` |
| NixOS only | `modules/home/shell/nixos.nix` |

```nix
# Example: modules/home/shell/default.nix
programs.zsh.shellAliases = {
  ll = "ls -la";
  gs = "git status";
};
```

### Changing System Settings

**macOS preferences** (dock, keyboard, trackpad, etc.):
```nix
# modules/darwin/system.nix
system.defaults.dock.autohide = true;
system.defaults.NSGlobalDomain.KeyRepeat = 2;
```

### Configuring Programs

**Git:**
```nix
# modules/home/git.nix - settings apply to all machines
```

**Neovim:**
```nix
# modules/home/neovim/init.lua - Lua configuration
# modules/home/neovim/default.nix - Nix packages (LSPs, formatters)
```

**Shell (zsh):**
```nix
# modules/home/shell/default.nix
programs.zsh.initContent = ''
  # Custom shell functions here
'';
```

### Pinning Package Versions

```nix
# overlays/default.nix
[
  (final: prev: {
    # Use unstable version
    foo = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.foo;

    # Pin specific version
    bar = prev.bar.overrideAttrs (old: {
      version = "1.2.3";
      src = prev.fetchFromGitHub { /* ... */ };
    });
  })
]
```

### Adding a New Machine

1. Create host config:
   ```bash
   mkdir -p hosts/darwin/new-machine  # or hosts/nixos/new-machine
   ```

2. Create `hosts/darwin/new-machine/default.nix`:
   ```nix
   { username, ... }:
   {
     imports = [
       ../../../modules/darwin/system.nix
       ../../../modules/darwin/homebrew.nix
     ];

     nixpkgs.config.allowUnfree = true;
     nix.settings.experimental-features = [ "nix-command" "flakes" ];
     nixpkgs.hostPlatform = "aarch64-darwin";
     system.stateVersion = 6;
     system.primaryUser = username;

     users.users.${username}.home = "/Users/${username}";
     home-manager.users.${username}.home.homeDirectory = "/Users/${username}";
   }
   ```

3. Add to `flake.nix`:
   ```nix
   darwinConfigurations = {
     # Key must match actual hostname for `darwin-rebuild switch --flake .` to work
     "Your-MacBook-Pro" = lib.mkDarwinHost {
       hostname = "Your-MacBook-Pro";  # Actual machine hostname
       hostDir = "new-machine";        # Directory name in hosts/darwin/ (optional, defaults to hostname)
       username = "youruser";
       email = "you@example.com";
       profile = "workstation";  # or "server"
     };
   };
   ```

4. Build:
   ```bash
   darwin-rebuild switch --flake .  # Uses hostname automatically
   # or explicitly:
   darwin-rebuild switch --flake .#Your-MacBook-Pro
   ```

## Directory Structure

```
nix-config/
├── flake.nix                 # Entry point, machine definitions
├── lib/default.nix           # Helper functions (mkDarwinHost, mkNixosHost)
│
├── hosts/                    # Machine-specific configs
│   ├── darwin/
│   │   └── macbook-pro/
│   └── nixos/
│
├── profiles/                 # Role-based configurations
│   ├── base.nix              # All machines
│   ├── workstation.nix       # Dev machines (extends base)
│   └── server.nix            # Servers (extends base)
│
├── modules/
│   ├── darwin/               # macOS-only modules
│   │   ├── system.nix        # System preferences
│   │   ├── homebrew.nix      # Casks
│   │   └── apps/             # Custom macOS apps
│   ├── nixos/                # NixOS-only modules
│   └── home/                 # Cross-platform home-manager
│       ├── shell/            # Zsh configuration
│       ├── git.nix
│       ├── tools.nix         # direnv, zoxide, atuin
│       └── neovim/
│
├── overlays/default.nix      # Package overrides
└── secrets/                  # agenix secrets (future)
```

## Useful Commands

```bash
rebuild                        # Rebuild and switch to new config
update                         # Update flake inputs (nixpkgs, etc.)
nix flake check                # Validate flake without building
nix repl --file flake.nix      # Explore flake in REPL
```
