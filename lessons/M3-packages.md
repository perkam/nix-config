# M3: CLI Packages — Declarative Package Management

> **Goal**: Install CLI tools via nixpkgs declaratively. Learn to search for packages, try them temporarily, and add them permanently to your system.

## Prerequisites

- M2 complete — system preferences working
- `hosts/darwin/default.nix` building successfully

---

## Concepts

### nixpkgs — The Package Repository

nixpkgs is the largest package repository in existence (~100,000 packages). Every package is a derivation — a build recipe that produces a store path. `inputs.nixpkgs` in your flake is what gives you access to all of them.

```
Terraform analogy:
  nixpkgs is like a massive provider registry
  pkgs.ripgrep is like a data source that resolves to a specific build artifact
  environment.systemPackages = [ pkgs.git ]  →  resource "apt_package" "git" { state = "present" }
```

### The `pkgs` Argument

Inside any module, `pkgs` is the full nixpkgs package set — an attribute set with 100,000+ entries. `pkgs.git` is the git derivation. `pkgs.ripgrep` is ripgrep. You access any package by its attribute name.

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.git
    pkgs.vim
    pkgs.ripgrep    # the attribute name is ripgrep, even though the binary is rg
  ];
}
```

### `with pkgs;` — Reducing Repetition

Because you know what `with` does from P1-01, you can use this shorthand:

```nix
# Without with:
environment.systemPackages = [ pkgs.git pkgs.vim pkgs.ripgrep pkgs.bat ];

# With with: brings all of pkgs into scope
environment.systemPackages = with pkgs; [ git vim ripgrep bat ];
```

Both are identical. `with pkgs;` just saves typing `pkgs.` repeatedly.

### Trying Before Installing

Nix lets you try any package without adding it to your config:

```bash
# Temporary shell with a package (gone when you exit)
nix shell nixpkgs#bat
bat --help
exit    # bat is gone

# Run once without even entering a shell
nix run nixpkgs#cowsay -- "hello"
```

This is like having a Docker container for every package in existence — instant, isolated, disposable.

---

## Exercise 1: Try before you buy

Before adding anything to your config, try these:

```bash
# Better cat
nix shell nixpkgs#bat --command bat --help

# Fuzzy finder
nix shell nixpkgs#fzf --command fzf --version

# Search for a tool you use by name
nix search nixpkgs jq
nix search nixpkgs "json processor"
```

## Exercise 2: Add system packages

In `hosts/darwin/default.nix`, add:

```nix
environment.systemPackages = with pkgs; [
  # Core tools
  git
  curl
  wget

  # Modern CLI replacements
  bat        # better cat
  ripgrep    # better grep (binary: rg)
  fd         # better find
  eza        # better ls (binary: eza)
  fzf        # fuzzy finder
  jq         # JSON processor

  # Development tools
  direnv     # per-directory environments
  tree
  htop
];
```

**Note on package names**: The package name in nixpkgs doesn't always match the command name:
- `ripgrep` → binary is `rg`
- `eza` → binary is `eza` (but the old `exa` package is dead, use `eza`)
- Use `nix search nixpkgs <name>` when you're not sure

## Exercise 3: Build and verify

```bash
git add -A
darwin-rebuild switch --flake .

# Verify packages are available
which rg          # → /run/current-system/sw/bin/rg (or similar)
rg --version
bat --version
eza --version
jq --version
```

## Exercise 4: Explore a package in the store

```bash
# See where a package lives
which bat

# Find the store path (everything above /bin/)
dirname $(dirname $(which bat))
# → /nix/store/abc123-bat-0.24.0

# See what's in the package
ls $(dirname $(dirname $(which bat)))
```

---

## Comprehension Questions

1. **What does `with pkgs;` do?** Write out `with pkgs; [ git vim ripgrep ]` without using `with`.

2. **Where do packages actually live?** Run `which bat` — what path do you see? Why does Nix put packages there instead of `/usr/local/bin`?

3. **What's the difference between `nix shell nixpkgs#bat` and adding `bat` to `environment.systemPackages`?** In Ansible terms, what's the equivalent of each?

4. **You want to install `fd` but don't know its nixpkgs name.** The binary is `fd` but maybe the package has a different name. How do you find it?

5. **What happens if two packages provide the same binary name?** If you install both `vim` and `neovim`, both provide a `vi` command. How does Nix handle this? Does it error or pick one?
