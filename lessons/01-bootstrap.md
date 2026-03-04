# Lesson 1: Bootstrap

> **Goal**: Create a minimal `flake.nix` that uses nix-darwin to manage your Mac. By the end, you'll run `darwin-rebuild switch` and have Nix controlling your system.

## Prerequisites

- macOS on Apple Silicon
- Nix installed (`nix --version` works)
- Flakes enabled (add `experimental-features = nix-command flakes` to `~/.config/nix/nix.conf` if not already)

## Concepts

### What's a Flake?

A flake is a `flake.nix` file that declares:
- **inputs** — dependencies (like a `requirements.txt` or Terraform provider block)
- **outputs** — what this flake produces (like Terraform outputs, but for system configs, packages, etc.)

Think of it as a self-contained, reproducible project. The `flake.lock` file pins exact versions — same idea as Terraform's `.terraform.lock.hcl`.

```
Terraform analogy:
  provider "aws" { ... }    →  inputs.nixpkgs
  terraform { ... }          →  flake.nix structure
  .terraform.lock.hcl        →  flake.lock
```

### What's nix-darwin?

nix-darwin is to macOS what NixOS is to Linux — it lets you declare system configuration (defaults, packages, services) in Nix. Without it, Nix on macOS can only manage packages. With it, you can manage the whole system declaratively.

```
Ansible analogy:
  playbook.yml               →  flake.nix (entry point)
  roles/macos/               →  nix-darwin modules
  ansible-playbook apply     →  darwin-rebuild switch
```

### Generations

Every time you run `darwin-rebuild switch`, Nix creates a new **generation** — a snapshot of your system. You can roll back to any previous generation instantly. This is like Terraform state history, but automatic and always available.

## Exercises

### Exercise 1: Create flake.nix

Create `/Users/kacper/projects/nix-config/flake.nix` with the following structure. Fill in the blanks yourself:

```
{
  description = "___";  # Describe your config

  inputs = {
    # 1. Add nixpkgs — the main package repository
    #    Use the "nixos-unstable" branch from github:NixOS/nixpkgs
    #    Hint: the syntax is  name.url = "github:owner/repo/branch";

    # 2. Add nix-darwin — the macOS system manager
    #    Repo: github:LnL7/nix-darwin
    #    It should use YOUR nixpkgs (not its own copy)
    #    Hint: use  name.inputs.nixpkgs.follows = "nixpkgs";

    # 3. Add nix-homebrew — for managing Homebrew casks later
    #    Repo: github:zhaofengli/nix-homebrew
  };

  outputs = { self, nixpkgs, nix-darwin, nix-homebrew }: {
    # 4. Define a darwinConfigurations entry for your hostname
    #    Run `hostname -s` to find your hostname
    #    Hint: darwinConfigurations."<hostname>" = nix-darwin.lib.darwinSystem { ... };

    # Inside darwinSystem, you need:
    #   system = "aarch64-darwin";   (Apple Silicon)
    #   modules = [ ./hosts/darwin/default.nix ];
  };
}
```

**Hints:**
- `inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";`
- `follows` means "use the same nixpkgs I declared, don't fetch your own"
- Your hostname is what `hostname -s` returns

### Exercise 2: Create the host module

Create `hosts/darwin/default.nix`:

```nix
{ pkgs, ... }:

{
  # 1. Enable the Nix daemon (required for multi-user Nix)
  #    Hint: services.nix-daemon.enable = ___

  # 2. Allow unfree packages (like proprietary apps)
  #    Hint: nixpkgs.config.allowUnfree = ___

  # 3. Set which Nix features to enable
  #    Hint: nix.settings.experimental-features = ___

  # 4. Set your system state version (start with 5)
  #    Hint: system.stateVersion = ___

  # 5. Set the platform
  #    Hint: nixpkgs.hostPlatform = "aarch64-darwin";
}
```

### Exercise 3: First build

```bash
# Initialize git (flakes require a git repo)
cd /Users/kacper/projects/nix-config
git init
git add -A

# Build and switch
darwin-rebuild switch --flake .
```

If you get errors, read them carefully — Nix error messages tell you exactly what's wrong (usually a typo or missing attribute).

## Verification

Run these commands and confirm:

```bash
# 1. Check that darwin-rebuild succeeded
darwin-rebuild --list-generations

# 2. You should see generation 1
# 3. Check that Nix is managing the system
which darwin-rebuild

# 4. Inspect what the flake provides
nix flake show
```

## Comprehension Questions

Answer these before moving to Lesson 2:

1. **What does `follows` do?** If nix-darwin has its own nixpkgs input, and you also declared nixpkgs, what happens without `follows`? What happens with it?

2. **What's the difference between `nix build` and `darwin-rebuild switch`?** When would you use each?

3. **What is a generation?** If you break something in Lesson 2, how would you get back to your current working state?

4. **Why do we need `git init` and `git add`?** What happens if you create a new file but forget to `git add` it before building?

5. **In Terraform terms**, what's the equivalent of `flake.lock`? What command would you run to update your dependencies (like `terraform init -upgrade`)?
