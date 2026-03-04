# A1: Reading nixpkgs — callPackage and the Package Set

> **Goal**: Understand how nixpkgs packages are structured and how `callPackage` works. After this lesson, you can read any nixpkgs package definition and know how to add a custom package to your config.

## When to Start This Lesson

Start this when you need to:
- Modify a package from nixpkgs (different version, extra flags)
- Add a package that isn't in nixpkgs
- Understand an error about a specific package

---

## Concepts

### How nixpkgs Packages are Structured

Every package in nixpkgs is a `.nix` file that follows the same pattern — a function that takes its dependencies as arguments and returns a derivation:

```nix
# pkgs/tools/text/ripgrep/default.nix (simplified)
{ lib
, rustPlatform
, fetchFromGitHub
, pcre2
, withPcre2 ? true    # optional dependency with default
}:

rustPlatform.buildRustPackage {
  pname = "ripgrep";
  version = "14.0.3";

  src = fetchFromGitHub {
    owner = "BurntSushi";
    repo = "ripgrep";
    rev = "14.0.3";
    hash = "sha256-...";
  };

  buildInputs = lib.optional withPcre2 pcre2;

  meta = with lib; {
    description = "A fast line-oriented search tool";
    license = licenses.unlicense;
    mainProgram = "rg";
  };
}
```

**The key pattern**: `{ dep1, dep2, optionalDep ? default }:` — all dependencies come in as arguments, not from global state. This is why Nix packages are reproducible: they declare exactly what they need.

### What `callPackage` Does

You never call package functions directly. nixpkgs uses `callPackage` to do it:

```nix
# Conceptually, this is what nixpkgs does:
pkgs.ripgrep = callPackage ./ripgrep/default.nix { };
#                                                  ↑
#                             empty set = use all defaults
```

`callPackage` does two things:
1. Looks at the function's argument names (`lib`, `rustPlatform`, `fetchFromGitHub`, `pcre2`)
2. Automatically supplies them from `pkgs` by name

So `{ lib, rustPlatform, ... }:` automatically gets `pkgs.lib`, `pkgs.rustPlatform`, etc. You don't have to pass them manually.

**The override slot** — the `{}` at the end lets you override specific arguments:

```nix
# Use a different pcre2 version just for ripgrep:
pkgs.ripgrep = callPackage ./ripgrep/default.nix { pcre2 = pkgs.pcre2_10_43; };

# Disable pcre2 support:
pkgs.ripgrep = callPackage ./ripgrep/default.nix { withPcre2 = false; };
```

### Finding and Reading Package Definitions

```bash
# Open any package's source in your editor
nix edit nixpkgs#ripgrep
nix edit nixpkgs#neovim
nix edit nixpkgs#git

# Find where a package is defined
nix eval --raw nixpkgs#ripgrep.meta.position
```

Practice reading a few package definitions. The pattern is always the same.

### Adding Your Own Package

When a package isn't in nixpkgs, you write it yourself using the same pattern:

```nix
# packages/my-tool/default.nix
{ stdenv, fetchFromGitHub, cmake }:

stdenv.mkDerivation {
  pname = "my-tool";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "someone";
    repo = "my-tool";
    rev = "v1.0.0";
    hash = "sha256-...";    # run nix build and copy the hash from the error
  };

  buildInputs = [ cmake ];
}
```

Then reference it in your flake:

```nix
# In your packages module or directly in flake.nix:
environment.systemPackages = [
  (pkgs.callPackage ./packages/my-tool/default.nix { })
];
```

---

## Exercise 1: Read a real package

```bash
# Read the hello package — it's simple and well-written
nix edit nixpkgs#hello

# Answer these questions:
# 1. What are its build dependencies?
# 2. What builder does it use (mkDerivation, buildRustPackage, etc.)?
# 3. What is its source (fetchurl, fetchFromGitHub, etc.)?
```

## Exercise 2: Read a complex package

```bash
# Read a package you actually use
nix edit nixpkgs#ripgrep
# or
nix edit nixpkgs#neovim

# Identify: dependencies, optional features, build system
```

## Exercise 3: Write a simple package (optional)

Find a simple CLI tool on GitHub that isn't in nixpkgs. Write a `packages/mytool/default.nix` for it and add it to your system packages.

For the hash — run `nix build`, copy the expected hash from the error, and put it in the file.

---

## Comprehension Questions

1. **What does `callPackage` do with the function argument names?** If a package has `{ lib, curl, openssl }:`, what does callPackage supply for each?

2. **What is the `{}` at the end of `callPackage ./ripgrep.nix {}`?** When would you put something in it?

3. **Why are package dependencies function arguments** instead of global references? What would break if `curl` was accessed as a global instead of an argument?

4. **How do you get the hash for a `fetchFromGitHub` call?** What happens if you put a wrong hash?

5. **In Terraform terms**, what is `callPackage` most similar to? Think about how Terraform resolves module inputs.
