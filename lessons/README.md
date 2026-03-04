# Nix Learning Curriculum

A structured curriculum for learning Nix — from language fundamentals to a fully managed macOS + Linux homelab setup.

**Teaching format**: Conversational — work through each lesson with an AI tutor. Ask questions freely before moving on.

**Delivery format**: Present all lesson content (concepts, examples, exercises, comprehension questions) directly in the chat. Do NOT ask the learner to open lesson files — they are the source of truth for the tutor, not the student.

---

## Curriculum Overview

| Phase | Focus | Milestone |
|---|---|---|
| **P1: Language** | Nix syntax and module system | Can read any `.nix` file |
| **P2: Store & Derivations** | How Nix builds things | Understand build errors |
| **M: macOS Foundation** | Bootstrap → prefs → packages → homebrew | `darwin-rebuild switch` working |
| **D: Daily Driver** | Home Manager, modularization, dev shells | Full env from `git clone` |
| **A: Advanced Patterns** | callPackage, overrides, overlays | Custom packages in production |
| **L: Linux Homelab** | NixOS, services, remote deploy, secrets | Server managed from same flake |

---

## Lessons

### Phase 1: Language Fundamentals
Start here. The existing lessons (01-06) assumed language knowledge you didn't have — these fill that gap.

- **[P1-01](P1-01-values-and-sets.md)** — Values, Attribute Sets, `with`, `inherit`
- **[P1-02](P1-02-functions.md)** — Functions, `...`, `@`-pattern, currying
- **[P1-03](P1-03-let-if-import.md)** — `let...in`, `if...then...else`, `import`
- **[P1-04](P1-04-module-system.md)** — The Module System: imports, merging, `specialArgs`

### Phase 2: Store and Derivations
Understand what Nix actually does when it builds things.

- **[P2-01](P2-01-store.md)** — The Nix Store, profiles, generations, garbage collection
- **[P2-02](P2-02-derivations.md)** — Derivations, `stdenv.mkDerivation`, reading nixpkgs

### Phase M: macOS Foundation
Build your actual macOS system config, one lesson at a time.

- **[M1](M1-bootstrap.md)** — Flakes, `darwin-rebuild switch`, first generation ⭐
- **[M2](M2-system-preferences.md)** — `system.defaults`: keyboard, trackpad, Dock, Finder ⭐
- **[M3](M3-packages.md)** — `environment.systemPackages`, `nix shell`, searching nixpkgs ⭐
- **[M4](M4-homebrew.md)** — nix-homebrew, Homebrew casks, GUI apps ⭐

### Phase D: Daily Driver
Complete your development environment and make it fully reproducible.

- **[D1](D1-home-manager.md)** — Home Manager: zsh, git, dotfiles, `home.file` ⭐
- **[D2](D2-modularization.md)** — Module structure, `imports`, `specialArgs` ⭐
- **[D3](D3-dev-shells.md)** — `devShells`, `nix develop`, direnv integration ⭐

### Phase A: Advanced Patterns
When you need to customize or extend nixpkgs.

- **[A1](A1-callpackage.md)** — Reading nixpkgs, `callPackage`, adding custom packages
- **[A2](A2-overrides.md)** — `.override`, `.overrideAttrs`, customizing packages
- **[A3](A3-overlays.md)** — Overlays: global package modifications

### Phase L: Linux Homelab
Extend your config to a NixOS server. Reuse what you've already built.

- **[L1](L1-nixos-structure.md)** — NixOS in your flake, module reuse, `hardware-configuration.nix`
- **[L2](L2-services.md)** — Declaring services: Nginx, PostgreSQL, Docker
- **[L3](L3-remote-deployment.md)** — Remote deployment from your Mac
- **[L4](L4-secrets-agenix.md)** — Encrypted secrets with agenix

---

## Legacy Lessons
The original lessons are preserved below. They cover the same macOS content as M1-D2 but assume language knowledge from P1-P2.

- [01-bootstrap.md](01-bootstrap.md) → now M1
- [02-system-preferences.md](02-system-preferences.md) → now M2
- [03-packages.md](03-packages.md) → now M3
- [04-homebrew-integration.md](04-homebrew-integration.md) → now M4
- [05-home-manager.md](05-home-manager.md) → now D1
- [06-modularization.md](06-modularization.md) → now D2

---

## Background Reading

This curriculum draws from the [Nix Pills](https://nixos.org/guides/nix-pills/) tutorial series:

| Phase | Nix Pills chapters |
|---|---|
| P1 (Language) | 1-4 |
| P2 (Store) | 5-8 |
| M-D (Practical) | 10-11 (nix-shell, GC) |
| A (Advanced) | 12-14, 16-18 |
| L (NixOS) | All applied |
