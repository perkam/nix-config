# D1: Home Manager — Dotfiles as Code

> **Goal**: Use Home Manager to manage user-level configuration — shell, git, dotfiles. After this lesson, your entire development environment (shell config, git identity, editor settings, aliases) is declared in code and reproducible.

## Prerequisites

- M4 complete — Homebrew casks managed
- Working `flake.nix` with nixpkgs, nix-darwin, nix-homebrew

---

## Concepts

### System Config vs User Config

Everything so far has been **system-wide** — it affects all users and requires root. But most of your daily environment is **user-specific**: your shell config, git identity, editor settings, aliases.

```
Ansible analogy:
  nix-darwin          → playbook running as root (system level)
  home-manager        → playbook running as your user (dotfile management)

  system.defaults.*           → tasks with become: true
  home-manager.users.kacper.* → tasks with become_user: kacper
```

### What Home Manager Does

Home Manager manages your `$HOME`:
- `programs.zsh` → generates `~/.zshrc`
- `programs.git` → generates `~/.config/git/config`
- `home.file` → symlinks any arbitrary file into your home directory
- `home.packages` → installs packages for this user only

It replaces hand-crafted dotfiles with declarative, reproducible config.

### Integration Mode

Home Manager can run standalone (separate `home-manager switch` command) or as a module inside nix-darwin. We use the **module approach** — Home Manager config is activated as part of `darwin-rebuild switch`. No separate command.

---

## Exercise 1: Add Home Manager to `flake.nix`

```nix
{
  description = "kacper's macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";

    # Add home-manager:
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, nix-homebrew, home-manager }: {
    darwinConfigurations."kacpers-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        ./hosts/darwin/default.nix
        nix-homebrew.darwinModules.nix-homebrew
        # Add home-manager's darwin module:
        home-manager.darwinModules.home-manager
      ];
    };
  };
}
```

## Exercise 2: Configure Home Manager base

In `hosts/darwin/default.nix`, add the home-manager configuration block:

```nix
home-manager = {
  # Use the system-level nixpkgs (same packages, no version mismatch)
  useGlobalPkgs = true;
  # Install packages to the user profile
  useUserPackages = true;

  users.kacper = { pkgs, ... }: {
    home.username = "kacper";
    home.homeDirectory = "/Users/kacper";
    home.stateVersion = "24.11";    # don't change this after initial setup
  };
};
```

Read `users.kacper = { pkgs, ... }: { ... }` — this is a function (from P1-02). The key `"kacper"` has a function as its value. Home Manager calls that function and passes `pkgs` and other args. The `{ ... }` body is your user-level config.

## Exercise 3: Configure zsh

Inside the `users.kacper` block:

```nix
programs.zsh = {
  enable = true;

  # Suggest commands as you type based on history
  autosuggestion.enable = true;

  # Color valid/invalid commands
  syntaxHighlighting.enable = true;

  history = {
    size = 10000;
    ignoreDups = true;
    share = true;    # share history between terminal windows
  };

  shellAliases = {
    ll = "eza -la --git";
    lt = "eza --tree --level=2";
    cat = "bat";
    grep = "rg";
    find = "fd";
    rebuild = "darwin-rebuild switch --flake ~/projects/nix-config";
  };

  initExtra = ''
    # Any custom zsh config that Home Manager doesn't have options for
    export EDITOR="vim"
    export LANG="en_US.UTF-8"
  '';
};
```

## Exercise 4: Configure git

Inside the `users.kacper` block:

```nix
programs.git = {
  enable = true;
  userName = "Kacper";
  userEmail = "your@email.com";    # fill in your actual email

  extraConfig = {
    init.defaultBranch = "main";
    pull.rebase = true;
    push.autoSetupRemote = true;
    core.autocrlf = "input";
  };

  # prettier diffs
  delta.enable = true;
};
```

## Exercise 5: Arbitrary dotfiles with `home.file`

For config files that Home Manager doesn't have a specific module for:

```nix
# Symlinks a file from your nix-config repo into your home directory
home.file.".config/starship.toml".source = ./starship.toml;

# Or write the content inline:
home.file.".config/starship.toml".text = ''
  [character]
  success_symbol = "[→](bold green)"
  error_symbol = "[→](bold red)"
'';

# Or manage a whole directory:
home.file.".config/nvim".source = ./nvim;
```

The source paths are relative to the file declaring them. This is the escape hatch for anything Home Manager doesn't have a module for.

## Exercise 6: Build and verify

```bash
git add -A
darwin-rebuild switch --flake .

# Open a NEW terminal window (zsh config changed)

# Verify Home Manager applied
cat ~/.zshrc
# → Should show a Nix-generated file header

# Test aliases
ll              # should run eza -la
rebuild         # should run darwin-rebuild switch

# Verify git config
git config --global user.name
git config --global user.email

# Test git delta
git diff HEAD   # should show colored delta output
```

---

## Comprehension Questions

1. **What's the difference between `environment.systemPackages` and `home.packages`?** If you add `pkgs.ripgrep` to both, what happens? Where should CLI tools go?

2. **What does `useGlobalPkgs = true` do?** What would happen without it? (Hint: think about `follows` — same concept at a different level.)

3. **What happened to your old `~/.zshrc`?** Check if there's a backup. What would happen if you manually edit `~/.zshrc` after Home Manager generates it?

4. **What is `home.file` for?** Give an example of a config file where you'd use `home.file` instead of a `programs.*` module.

5. **Your entire development environment is now declared in code.** Walk through exactly what you'd do to set up an identical environment on a new Mac — what are the steps after installing Nix?
