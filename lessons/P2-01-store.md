# P2-01: The Nix Store

> **Goal**: Understand what `/nix/store/` is, how it works, and why it's the foundation of everything Nix does. After this lesson, Nix error messages referencing store paths will make sense, and you'll understand why builds are reproducible.

## Prerequisites

- P1-01 through P1-04 complete

---

## Concepts

### The Store is the Heart of Nix

Everything Nix builds, downloads, or installs goes into one place: `/nix/store/`. Nothing else on your system is touched (except symlinks pointing into the store).

```
/nix/store/
├── abc123aaaa-git-2.43.0/
│   └── bin/
│       └── git                ← the actual git binary
├── def456bbbb-git-2.43.0.drv  ← the recipe that built git
├── xyz789cccc-vim-9.0/
│   └── bin/
│       └── vim
└── ...                        ← 80,000+ paths for a typical system
```

**Key property**: Everything in the store is **immutable**. Once a path is created, it's never modified. Builds produce new paths; they never change existing ones.

---

### The Hash — Content-Addressed Storage

Every store path starts with a hash:

```
/nix/store/abc123aaaa-git-2.43.0/
            ↑
            This is computed from ALL inputs:
            - the source code of git
            - every build dependency (gcc, glibc, make, ...)
            - every build script
            - every environment variable used in the build
            - the build instructions themselves
```

**The implication**: Same inputs → same hash → same path. Always. On any machine.

This is what makes Nix reproducible. If you and a colleague both have the same `flake.lock`, you'll get the same hashes, the same store paths, and the same binaries.

**Terraform analogy**: Like a Terraform resource that's identified by the hash of its configuration. Change the config → different resource. Same config on two machines → identical resource.

---

### Why Packages Don't Conflict

Traditional package managers put everything in `/usr/local/bin/`. Two packages providing the same file conflict. Nix avoids this completely:

```
/nix/store/abc123-python-3.11/bin/python3
/nix/store/def456-python-3.12/bin/python3
```

These can coexist because they're at different paths. You can have Python 3.11 and 3.12 installed simultaneously with no conflict.

**How do you use them?** Through **profiles**.

---

### Profiles — How You Access Store Paths

The store is just files. You access them through a **profile** — a directory of symlinks that points into the store.

```
~/.nix-profile/           ← your user profile (a symlink farm)
├── bin/
│   ├── git → /nix/store/abc123-git-2.43.0/bin/git
│   ├── vim → /nix/store/xyz789-vim-9.0/bin/vim
│   └── ...
└── ...
```

Your shell's `PATH` includes `~/.nix-profile/bin`, so `which git` resolves through the profile to the store.

For nix-darwin, there's also a system profile:

```
/run/current-system → /nix/store/hhh999-darwin-system-26.05/
```

When `darwin-rebuild switch` finishes, it updates this symlink to point to the newly built system derivation.

---

### Generations — Free Rollback

Every time you install something or run `darwin-rebuild switch`, Nix creates a new **generation** — a new profile that points to the updated set of store paths. Old generations are kept.

```
/nix/var/nix/profiles/system-1-link → /nix/store/aaa-darwin-system/   ← generation 1
/nix/var/nix/profiles/system-2-link → /nix/store/bbb-darwin-system/   ← generation 2
/nix/var/nix/profiles/system       → system-2-link                    ← current
```

Rolling back is just updating the `current` symlink:

```bash
darwin-rebuild --rollback    # switches /run/current-system to previous generation
```

**The store paths from old generations are still there** — nothing was deleted. Rollback is instant because it's just a symlink change.

**Ansible analogy**: Ansible has no native rollback. You'd have to manually undo every change or restore from a backup. Nix gives you rollback for free because the old state still exists in the store.

---

### Closures — Complete Dependency Sets

A **closure** is a store path plus all its transitive dependencies. It's everything you need to use something — not just the package itself but every library it links against, every tool it calls.

```bash
# See the closure of git
nix-store --query --requisites $(which git | xargs dirname | xargs dirname)
```

The closure of `git` includes: git itself, plus its C runtime (glibc), plus SSL libraries, plus everything else it depends on at runtime.

**Why closures matter**: When you copy a package to another machine (or build it in a sandbox), you copy the closure. Nothing is missing. This is how Nix achieves "it works on my machine" being meaningful.

---

### Garbage Collection

The store grows over time. Old generations, old packages, cached builds — they accumulate. Nix has a garbage collector to reclaim space.

The GC works by tracing **GC roots** — paths in `/nix/var/nix/gcroots/` that mark what's "live". Anything not reachable from a root is garbage.

```
GC roots include:
- current system profile (/run/current-system)
- current user profiles (~/.nix-profile)
- older generations (until you delete them)
- active nix-shell environments
```

```bash
# Delete old generations first (optional, frees roots)
darwin-rebuild --delete-generations 14d   # delete generations older than 14 days

# Collect garbage (delete unreachable store paths)
nix-collect-garbage

# Or do both at once (more aggressive)
nix-collect-garbage -d    # -d deletes ALL old generations then collects
```

**Warning**: `nix-collect-garbage -d` deletes ALL previous generations. After running it, you can't roll back. Only run it when you're confident the current system works.

---

## Exploration Exercises

These are read-only — just explore and observe.

**Exercise 1: Look at the store**
```bash
# See how many store paths you have
ls /nix/store | wc -l

# Look at a few store paths
ls /nix/store | head -20

# Find git in the store
ls /nix/store | grep git
```

**Exercise 2: Trace your profile**
```bash
# See your nix profile
ls -la ~/.nix-profile

# See what's in it
ls ~/.nix-profile/bin | head -20

# Follow a symlink to the store
ls -la $(which git)
# You'll see something like: /nix/store/abc123-git/bin/git
```

**Exercise 3: Inspect a closure**
```bash
# Install hello temporarily and inspect it
nix shell nixpkgs#hello --command hello

# Find hello in the store
ls /nix/store | grep hello

# See its dependencies (closure minus itself)
nix-store --query --references /nix/store/<the-hello-path>
```

**Exercise 4: Check your generations**
```bash
# List darwin generations (once darwin-rebuild has been run)
darwin-rebuild --list-generations

# Or nix user generations
nix-env --list-generations
```

---

## Comprehension Questions

1. **What is the hash in a store path computed from?** If you change one build dependency (e.g., upgrade gcc), does the hash of the package being built change? Why?

2. **What is a generation?** If you run `darwin-rebuild switch` three times, how many generations exist? Can you access generation 1 after generation 3 is current?

3. **What is a closure?** If git is in the store but its SSL dependency is not, what happens when you run git?

4. **What does `nix-collect-garbage -d` do in two steps?** Why is the order (generations first, then GC) important?

5. **In Terraform terms**, what is the equivalent of Nix generations? What's the equivalent of rollback? How does Nix's approach differ from Terraform state management?
