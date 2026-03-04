# Lesson 3: CLI Packages

> **Goal**: Install CLI tools declaratively via nixpkgs. Learn how to search for packages, try them temporarily, and make them permanent.

## Prerequisites

- Lesson 2 complete — system preferences managed by nix-darwin
- Working `hosts/darwin/default.nix`

## Concepts

### nixpkgs — The Package Repository

nixpkgs is the largest package repository in existence (~100,000 packages). It's what `inputs.nixpkgs` points to in your flake. Every package is built from source in a sandbox, then cached as a binary.

```
Ansible analogy:
  apt: name=ripgrep state=present     →  environment.systemPackages = [ pkgs.ripgrep ];

Terraform analogy:
  nixpkgs is like a massive provider
  pkgs.ripgrep is like a data source that resolves to a specific build
```

### System Packages vs User Packages

nix-darwin has `environment.systemPackages` — packages available to all users. Later (Lesson 5), Home Manager adds per-user packages. For now, system packages are fine.

### Trying Before Committing

Nix has a unique feature — you can try any package without installing it:

```bash
# Temporary shell with a package
nix shell nixpkgs#cowsay
cowsay "hello"
# Exit the shell and cowsay is gone

# Run a package once without even entering a shell
nix run nixpkgs#cowsay -- "hello"
```

This is like having a Docker container for every package in existence, but instant.

### Searching for Packages

```bash
# Search on the command line
nix search nixpkgs ripgrep

# Or use the web: https://search.nixos.org/packages
```

### The `pkgs` Argument

In your module, `pkgs` is the full nixpkgs package set. `pkgs.ripgrep` is the ripgrep package. `pkgs.git` is git. You reference packages by their attribute name (which you find via `nix search`).

## Exercises

### Exercise 1: Try before you buy

Before adding anything to your config, try these packages temporarily:

```bash
# 1. Try bat (a better cat)
nix shell nixpkgs#bat
bat --help
exit

# 2. Try ripgrep
nix shell nixpkgs#ripgrep
rg --help
exit

# 3. Search for a package you use daily
nix search nixpkgs <something>
```

### Exercise 2: Add system packages

In `hosts/darwin/default.nix`, add a `environment.systemPackages` list:

```nix
# Add this to your existing config:
environment.systemPackages = with pkgs; [
  # Core tools — add these:
  # git, vim, curl, wget

  # Modern CLI replacements — search for and add:
  # bat (better cat), ripgrep (better grep), fd (better find),
  # eza (better ls), fzf (fuzzy finder), jq (JSON processor)

  # Development tools — add what you use:
  # direnv, tree, htop, tldr
];
```

**Hints:**
- The `with pkgs;` prefix means you can write `git` instead of `pkgs.git`
- Package names in nixpkgs don't always match the command name — use `nix search` to find them
- `eza` is the package name (successor to `exa`)

### Exercise 3: Build and verify

```bash
git add -A
darwin-rebuild switch --flake .

# Verify packages are available
which ripgrep   # Might not work — the binary name could differ
rg --version    # This is the actual binary name
bat --version
fd --version
eza --version
```

### Exercise 4: Explore a package

```bash
# See where a package lives in the Nix store
which bat
# Output: /nix/store/<hash>-bat-<version>/bin/bat

# See what's inside a package
ls $(dirname $(dirname $(which bat)))

# List all files in a package
nix path-info -r $(which bat | xargs dirname | xargs dirname)
```

## Verification

```bash
# All these should work:
git --version
bat --version
rg --version
fd --version
eza --list
fzf --version
jq --version

# Your generation should have incremented
darwin-rebuild --list-generations
```

## Comprehension Questions

1. **What does `with pkgs;` do?** What would the list look like without it? (Write out 3 entries both ways.)

2. **Where do packages actually live?** If you run `which bat`, you'll see a path in `/nix/store/`. Why does Nix put packages there instead of `/usr/local/bin`?

3. **What happens if two packages provide the same binary name?** For example, if you install both `vim` and `neovim`, both provide a `vi` command. How does Nix handle this?

4. **Compare `nix shell nixpkgs#bat` with `environment.systemPackages`**. In Ansible terms, what's the equivalent of each? (Think ephemeral vs desired state.)

5. **You want a package but don't know its nixpkgs name.** The command is called `rg` but the package isn't `pkgs.rg`. How do you find the right attribute name? Try finding the package name for the `fd` command.
