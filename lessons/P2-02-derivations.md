# P2-02: Derivations and How Packages are Built

> **Goal**: Understand what a derivation is, how packages in nixpkgs are structured, and how to read a basic package definition. You don't need to write derivations from scratch — but you need to recognize them and understand what they produce.

## Prerequisites

- P2-01 complete — understand the Nix store
- `nix repl` open

---

## Concepts

### What is a Derivation?

A derivation is a **build recipe** stored in the Nix store as a `.drv` file. It specifies:
- What inputs are needed (other store paths)
- What builder to run (usually bash)
- What environment variables to set during the build
- Where the output should go (a new store path)

Every package in nixpkgs is ultimately a derivation. Every system config produced by nix-darwin is a derivation. Everything Nix builds starts as a derivation.

**Two phases**:
1. **Evaluation** — Nix reads your `.nix` files and computes derivations. Pure, no builds happen. Fast.
2. **Realisation** — The Nix daemon builds the derivations. Downloads, compiles, installs to the store.

```
.nix files
  → Nix evaluates them  (pure computation, produces .drv files)
  → Nix daemon builds .drv files  (real work, produces store paths)
  → darwin-rebuild activates the result  (symlinks, services, etc.)
```

---

### The Primitive `derivation` Built-in

At the lowest level, all derivations are created by calling the `derivation` built-in:

```nix
derivation {
  name = "my-output";
  system = "aarch64-darwin";
  builder = "/bin/sh";
  args = [ "-c" "echo hello > $out" ];
}
```

This creates a `.drv` file. When built, it runs the builder script and puts the result at `$out` (the output store path).

**You will never write this directly**. It's a primitive. Everyone uses `stdenv.mkDerivation` instead, which wraps it with sensible defaults.

---

### `stdenv.mkDerivation` — The Standard Package Builder

`stdenv.mkDerivation` is the function used to build almost every C/C++ package (and many others) in nixpkgs:

```nix
{ stdenv, fetchurl }:

stdenv.mkDerivation {
  pname = "hello";          # package name
  version = "2.12";         # version

  src = fetchurl {           # download the source
    url = "mirror://gnu/hello/hello-2.12.tar.gz";
    sha256 = "abc123...";   # hash verifies the download
  };

  # stdenv provides standard build phases by default:
  # unpackPhase → configurePhase (./configure) → buildPhase (make) → installPhase (make install)
  # You only override the phases that need changing
}
```

The `{ stdenv, fetchurl }:` at the top — this is a function. When nixpkgs calls it via `callPackage`, it supplies `stdenv` and `fetchurl` automatically.

---

### How to Read a nixpkgs Package

When you need to modify a package or understand what it does, you read its source. Here's how to find it:

```bash
# Open the definition of any package in your editor
nix edit nixpkgs#git
nix edit nixpkgs#ripgrep
nix edit nixpkgs#vim
```

A typical package looks like this (simplified ripgrep):

```nix
{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname = "ripgrep";
  version = "14.0.3";

  src = fetchFromGitHub {
    owner = "BurntSushi";
    repo = "ripgrep";
    rev = "14.0.3";
    hash = "sha256-...";
  };

  cargoHash = "sha256-...";

  meta = {
    description = "A fast line-oriented search tool";
    license = lib.licenses.unlicense;
    mainProgram = "rg";
  };
}
```

The pattern is always: `{ dependencies... }: someBuilder { ... }`.

**What `rustPlatform.buildRustPackage` is**: Like `stdenv.mkDerivation` but for Rust packages. nixpkgs has platform-specific builders for Rust, Python, Go, Haskell, etc. They all wrap `derivation` at the bottom.

---

### `nix build` and `nix shell` — Working with Derivations

You can build any derivation from nixpkgs directly:

```bash
# Build hello, put result at ./result
nix build nixpkgs#hello
./result/bin/hello    # runs it

# Try a package without installing it
nix shell nixpkgs#ripgrep
rg --version
exit

# Run a package once
nix run nixpkgs#cowsay -- "hello"

# See what WOULD be built (dry run)
nix build nixpkgs#git --dry-run
```

---

### Reading Error Messages

When a build fails, Nix tells you which derivation failed. Learning to read these makes debugging much faster:

```
error: builder for '/nix/store/abc123-ripgrep-14.0.3.drv' failed with exit code 1
```

This means:
- The derivation at that store path failed to build
- The exit code tells you if it was a compilation error (1), missing file (2), etc.
- Nix keeps the build log — run `nix log /nix/store/abc123-ripgrep-14.0.3.drv` to see it

For darwin-rebuild failures, the error usually points to the specific option or module that caused the problem — much more informative than Ansible's task output.

---

### What You DO and DON'T Need to Know

**You DO need to know**:
- What a derivation is (a build recipe that produces a store path)
- The two-phase model (evaluate → build)
- How to read a basic `mkDerivation` call
- How to use `nix build`, `nix shell`, `nix run`
- How to find a package's source with `nix edit`

**You do NOT need to know** (for system configuration):
- How to write `derivation { }` from scratch
- How `stdenv` sets up the build environment internally
- How `.drv` files are formatted
- How build sandboxing works

These become relevant in Phase A (Advanced Patterns) when you want to add custom packages.

---

## Exercises

**Exercise 1: Try packages without installing**
```bash
# Try a few packages temporarily
nix shell nixpkgs#hello --command hello
nix shell nixpkgs#bat --command bat --version
nix run nixpkgs#cowsay -- "Nix is neat"
```

**Exercise 2: Build something and inspect the result**
```bash
nix build nixpkgs#hello
ls -la result
ls result/bin/
./result/bin/hello

# The result symlink points into the store:
ls -la result    # → result → /nix/store/abc123-hello-2.12
```

**Exercise 3: Read a package definition**
```bash
nix edit nixpkgs#hello
# Look for: pname, version, src, buildInputs, meta
# Close without editing
```

**Exercise 4: Explore the derivation**
```bash
# See the .drv file for hello
nix show-derivation nixpkgs#hello

# Look for: builder, args, env (the environment variables passed to the build)
```

**Exercise 5: Search for packages**
```bash
# Find packages by name
nix search nixpkgs ripgrep
nix search nixpkgs "json processor"

# Or browse: https://search.nixos.org/packages
```

---

## Comprehension Questions

1. **What are the two phases of a Nix build?** What happens in each phase? At which phase do network downloads happen?

2. **What is `stdenv.mkDerivation` and why does almost every package use it** instead of calling `derivation` directly?

3. **You run `nix shell nixpkgs#python3` and then `exit`.** Is Python still on your system? Where did it go? How is this different from `brew install python`?

4. **What does `nix build nixpkgs#hello` put in `./result`?** Is `result` the actual package or a symlink? Why?

5. **In Terraform terms**, what is a derivation? What's the equivalent of the two-phase (evaluate → build) model in Terraform? (Think about `terraform plan` vs `terraform apply`.)
