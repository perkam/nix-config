# A2: Overrides — Customizing Packages

> **Goal**: Modify packages from nixpkgs without forking them. Learn the three levels of override and when to use each.

## When to Start This Lesson

Start this when you need to:
- Disable failing tests in a package
- Enable an optional feature that's off by default
- Use a different version than what's in nixpkgs
- Apply a patch to a package

---

## Concepts

### Three Levels of Override

nixpkgs provides three ways to modify packages, in order of increasing power:

---

#### Level 1: `.override {}` — Change callPackage Arguments

Overrides the arguments passed to the package function (what `callPackage` supplies):

```nix
# Change which pcre2 ripgrep links against
pkgs.ripgrep.override { pcre2 = pkgs.pcre2; }

# Disable an optional feature
pkgs.ripgrep.override { withPcre2 = false; }

# Use a custom dependency
pkgs.curl.override { openssl = pkgs.openssl_legacy_provider; }
```

Use this when you want to change which dependencies a package uses or toggle feature flags declared as function arguments.

---

#### Level 2: `.overrideAttrs` — Change Derivation Attributes

Overrides attributes of the `stdenv.mkDerivation` call itself:

```nix
# Disable tests (common when tests fail on macOS)
pkgs.ripgrep.overrideAttrs (old: {
  doCheck = false;
})

# Add a patch
pkgs.vim.overrideAttrs (old: {
  patches = old.patches or [] ++ [ ./my-vim.patch ];
})

# Use a different version
pkgs.ripgrep.overrideAttrs (old: {
  version = "13.0.0";
  src = pkgs.fetchFromGitHub {
    owner = "BurntSushi";
    repo = "ripgrep";
    rev = "13.0.0";
    hash = "sha256-...";
  };
})

# Add extra build inputs
pkgs.neovim.overrideAttrs (old: {
  buildInputs = old.buildInputs ++ [ pkgs.tree-sitter ];
})
```

The `old:` argument gives you the original attributes so you can extend (with `++`) instead of replace.

Use this when you need to change how the package is built — version, source, patches, build flags, test behavior.

---

#### Level 3: `lib.makeExtensible` / `overlays` — System-Wide Overrides

Overlays apply modifications globally — they affect all packages that depend on the modified one. Covered in A3.

---

### Where to Put Overrides

**In a module** — for one-off modifications:

```nix
{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.ripgrep.overrideAttrs (old: { doCheck = false; }))
  ];
}
```

**In `nixpkgs.overlays`** — when you want the override everywhere:

```nix
{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      ripgrep = prev.ripgrep.overrideAttrs (old: { doCheck = false; });
    })
  ];
}
```

The overlay approach means that if any other package depends on ripgrep, it gets your modified version too.

---

## Exercise 1: Disable tests on a package

Find a package that runs tests during build and disable them:

```nix
# Add to your packages module:
environment.systemPackages = [
  (pkgs.ripgrep.overrideAttrs (old: {
    doCheck = false;
    meta = old.meta // { description = "ripgrep (tests disabled)"; };
  }))
];
```

Build and verify the package still works.

## Exercise 2: Add to an existing attribute

```nix
# Add an extra package to neovim's build inputs
let myNeovim = pkgs.neovim.overrideAttrs (old: {
  buildInputs = (old.buildInputs or []) ++ [ pkgs.tree-sitter ];
});
in ...
```

## Exercise 3: Use `.override` for a feature flag

```bash
# Find a package with optional features
nix edit nixpkgs#imagemagick
# Look for optional arguments (ones with defaults like: withFoo ? true)
```

Then override one of them in your config.

---

## Comprehension Questions

1. **What's the difference between `.override` and `.overrideAttrs`?** When would you use each? Give a concrete example for each.

2. **What does the `old:` argument in `overrideAttrs (old: { ... })` give you?** Why is it important when adding to a list vs. replacing a value?

3. **If you override a package in `environment.systemPackages` but not globally**, and another package depends on it, which version does that other package get?

4. **What does `old.patches or []` mean?** Why `or []` instead of just `old.patches`?

5. **In Ansible terms**, what is `overrideAttrs` most similar to? (Think about how you'd change one attribute of a role's defaults without rewriting the role.)
