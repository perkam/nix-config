# M4: Homebrew Integration — Declarative GUI Apps

> **Goal**: Use nix-homebrew to manage macOS GUI apps (casks) declaratively alongside your Nix packages. After this lesson, your entire software installation — CLI and GUI — is declared in code.

## Prerequisites

- M3 complete — CLI packages managed via nixpkgs
- `nix-homebrew` already in your `flake.nix` inputs (you added it in M1)

---

## Concepts

### Why Homebrew When We Have Nix?

Nix handles CLI tools beautifully. But macOS GUI apps (`.app` bundles) are a different story. Many apps — 1Password, Slack, browsers, professional tools — are distributed as proprietary pre-built binaries. They aren't in nixpkgs, and packaging them there would require re-distributing proprietary code.

Homebrew Casks handle these: they download the vendor's own binary and put it in `/Applications/`. nix-homebrew lets you manage Homebrew itself declaratively through Nix.

```
Terraform analogy:
  Nix packages    → your primary provider (AWS)
  Homebrew casks  → a secondary provider for resources your primary can't handle
  You declare both in the same flake, they work together
```

### `follows` Revisited

`nix-homebrew` has its own `nixpkgs` input. If you don't use `follows`, your `flake.lock` will contain two separate versions of nixpkgs — one for your config, one for nix-homebrew. That means more downloads and possible version mismatches.

You'll add `follows` for nix-homebrew when wiring it up.

### Casks vs Formulae

- **Formulae** — CLI tools Homebrew compiles from source. You don't need these — use `environment.systemPackages` instead.
- **Casks** — pre-built macOS `.app` bundles. This is what Homebrew is for in a Nix setup.

---

## Exercise 1: Wire up nix-homebrew in `flake.nix`

Update your `flake.nix` — add `follows` for nix-homebrew and pass it to your darwin configuration:

```nix
{
  description = "kacper's macOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Add follows for nix-homebrew:
    nix-homebrew.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, nix-homebrew }: {
    darwinConfigurations."kacpers-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [
        ./hosts/darwin/default.nix
        # Add the nix-homebrew module:
        nix-homebrew.darwinModules.nix-homebrew
      ];
    };
  };
}
```

`nix-homebrew.darwinModules.nix-homebrew` is a module from the nix-homebrew flake. Adding it to your `modules` list makes the `nix-homebrew` and `homebrew` options available in your modules.

## Exercise 2: Configure nix-homebrew

In `hosts/darwin/default.nix`, add the nix-homebrew configuration:

```nix
# Nix-homebrew configuration (manages Homebrew itself)
nix-homebrew = {
  enable = true;
  user = "kacper";     # the user that owns the Homebrew installation
  autoMigrate = true;  # adopt existing Homebrew installation (if any)
};
```

## Exercise 3: Declare your casks

In `hosts/darwin/default.nix`, add:

```nix
# Homebrew cask management
homebrew = {
  enable = true;

  casks = [
    # Add GUI apps you actually use — examples:
    # "ghostty"
    # "firefox"
    # "visual-studio-code"
    # "1password"
    # "raycast"
    # "iterm2"
    # "slack"
  ];

  # What to do with casks not in this list:
  # "zap"       = uninstall unlisted casks (strict — like Terraform destroy)
  # "uninstall" = uninstall but leave data
  # "none"      = leave unlisted casks alone (safe default to start)
  onActivation.cleanup = "none";

  # Keep Homebrew up to date on each rebuild
  onActivation.autoUpdate = true;
  onActivation.upgrade = true;
};
```

**Warning about `cleanup = "zap"`**: If you enable this, any cask not listed here gets uninstalled on the next rebuild. Start with `"none"` until you've listed everything you want to keep.

## Exercise 4: Build and verify

```bash
git add -A
darwin-rebuild switch --flake .

# This takes longer the first time — Homebrew is being set up

# Verify Homebrew is managed by Nix
brew --version
brew list --cask

# Check that your apps installed
ls /Applications/ | grep -i <your-app-name>
```

---

## Comprehension Questions

1. **Why not use nixpkgs for GUI apps?** What's the technical reason Homebrew Casks are still necessary on macOS?

2. **What does `nix-homebrew.inputs.nixpkgs.follows = "nixpkgs"` prevent?** Open `flake.lock` before and after adding `follows` — what changes?

3. **What does `onActivation.cleanup = "zap"` do?** How is this similar to Terraform's default lifecycle (`terraform destroy` removes resources not in state)? What's the `"none"` equivalent in Terraform terms?

4. **Casks vs system packages**: You now have two ways to install software. When would you use each? Give one concrete example for each category.

5. **What happens if you remove a cask from the list** with `cleanup = "none"` vs `cleanup = "zap"`? Which behavior matches Terraform? Which matches Ansible's default?
