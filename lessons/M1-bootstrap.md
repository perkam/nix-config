# M1: Bootstrap — Your First Darwin Configuration

> **Goal**: Create a working `flake.nix` and `hosts/darwin/default.nix`. Run `darwin-rebuild switch` successfully. You'll have Nix controlling your Mac and your first generation recorded.

## Prerequisites

- P1-01 through P1-04 complete — you can read Nix syntax fluently
- P2-01 through P2-02 complete — you understand the store and derivations
- Nix installed, flakes enabled (`~/.config/nix/nix.conf` has `experimental-features = nix-command flakes`)
- Hostname: run `hostname -s` (yours is `kacpers-MacBook-Pro`)

---

## Concepts

### Flakes — Reproducible Entry Points

A flake is a directory with a `flake.nix` that declares `inputs` and `outputs`. It's the standard way to structure any Nix project — including your system config.

```
Terraform analogy:
  flake.nix          → main.tf + provider declarations
  flake.lock         → .terraform.lock.hcl  (exact pinned versions)
  inputs             → required_providers { ... }
  outputs            → output { ... }       (but also resources, not just outputs)
  darwin-rebuild switch  → terraform apply
```

**`flake.lock`** is generated automatically the first time you build. It pins every input to an exact git commit. Same lock file → same packages → reproducible system. Commit `flake.lock` to git.

### The nix-darwin Module

`nix-darwin.lib.darwinSystem` is a function that takes your modules and produces a derivation — the complete macOS system configuration. When built and activated, it:
- Sets macOS system preferences
- Manages packages in your PATH
- Configures services (Nix daemon, launchd agents)
- Writes config files

The activation is the `darwin-rebuild switch` step — it builds the derivation and runs its `activate` script.

### `nixpkgs.hostPlatform`

You'll set this in your host module (not in `darwinSystem`). It tells the module system what platform to target:

```nix
nixpkgs.hostPlatform = "aarch64-darwin";    # Apple Silicon Mac
```

---

## Exercise 1: Create `flake.nix`

Create `/Users/kacper/projects/nix-config/flake.nix`:

```nix
{
  description = "kacper's macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = { self, nixpkgs, nix-darwin, nix-homebrew }: {
    darwinConfigurations."kacpers-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/darwin/default.nix ];
    };
  };
}
```

**Read it before saving** — you should be able to explain every line now:
- `outputs = { self, nixpkgs, nix-darwin, nix-homebrew }:` — a function taking the resolved inputs as an attribute set
- `{ ... }` after the `:` — the return value: an attribute set of outputs
- `nix-darwin.lib.darwinSystem { ... }` — calling a function from the nix-darwin flake
- `modules = [ ./hosts/darwin/default.nix ]` — a list with one path: the module file we'll create next

---

## Exercise 2: Create the host module

Create the directory and file:

```bash
mkdir -p /Users/kacper/projects/nix-config/hosts/darwin
```

Create `/Users/kacper/projects/nix-config/hosts/darwin/default.nix`:

```nix
{ pkgs, ... }:

{
  # Nix daemon — required for multi-user Nix on macOS
  services.nix-daemon.enable = true;

  # Allow installing packages with non-free licenses
  nixpkgs.config.allowUnfree = true;

  # Enable flakes and the new nix CLI (managed here instead of nix.conf)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Target platform — Apple Silicon
  nixpkgs.hostPlatform = "aarch64-darwin";

  # State version — start at 5, don't change it later
  # Read the changelog before bumping: $ darwin-rebuild changelog
  system.stateVersion = 5;
}
```

**What each option does**:
- `services.nix-daemon.enable` — manages the Nix daemon as a launchd service
- `nixpkgs.config.allowUnfree` — lets you install things like 1Password, Slack
- `nix.settings.experimental-features` — once nix-darwin manages this, you can remove it from `~/.config/nix/nix.conf`
- `nixpkgs.hostPlatform` — tells nixpkgs which platform to build packages for
- `system.stateVersion` — tracks which nix-darwin version initialized your system

---

## Exercise 3: Initialize git and build

Flakes require a git repository — Nix won't evaluate files that aren't tracked by git.

```bash
cd /Users/kacper/projects/nix-config

# Initialize git
git init
git add .

# Build and switch — this takes a few minutes the first time
darwin-rebuild switch --flake .
```

**What to expect**:
- First run downloads nixpkgs and nix-darwin (large downloads)
- You'll see it building the system derivation
- It may ask for your password (to activate system changes)
- On success: "darwin-rebuild: generation X created"

**If you get errors**: Read them carefully. Nix errors usually point exactly to the file and option that's wrong. Common first-run issues:
- `nix-darwin not installed` → follow the nix-darwin installer first
- `attribute 'nix-daemon' missing` → check nix-darwin version compatibility
- Syntax errors → re-check your `.nix` files for typos

---

## Exercise 4: Verify

```bash
# Check that darwin-rebuild succeeded and created generation 1
darwin-rebuild --list-generations

# Check that Nix is managing the system
which darwin-rebuild
# Should be in /run/current-system/sw/bin/ or similar

# See what your flake produces
nix flake show

# The darwin-rebuild switch moved control of nix-daemon here:
# ~/.config/nix/nix.conf can now be simplified or left as-is
```

---

## Comprehension Questions

1. **What does `nix-darwin.inputs.nixpkgs.follows = "nixpkgs"` do?** If you remove this line, what happens in `flake.lock`? (Hint: how many copies of nixpkgs would there be?)

2. **Why did we need `git init` and `git add`?** What happens if you create a new `.nix` file but forget to `git add` it before running `darwin-rebuild switch`?

3. **What is a generation?** After running `darwin-rebuild switch` three times, how many generations exist? How would you roll back to generation 1?

4. **What's the difference between `nix build` and `darwin-rebuild switch`?** If you just wanted to check your config compiles without applying it, what would you run?

5. **In Terraform terms**, what is `flake.lock`? What command would you run to update all inputs to their latest versions? (Hint: `nix flake update`)
