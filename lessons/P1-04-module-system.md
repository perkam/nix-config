# P1-04: The Module System

> **Goal**: Understand how nix-darwin and NixOS modules work — what they are, how they compose, and how the merge system works. This is the system you'll use in every lesson from here on.

## Prerequisites

- P1-01 through P1-03 complete
- You can read any basic `.nix` file

---

## Concepts

### What Problem the Module System Solves

You have a macOS config. It has system preferences, packages, Homebrew casks, shell config. If you put all of this in one file, it becomes 500 lines long and hard to maintain.

You could split it into files. But then how do multiple files each contribute to `environment.systemPackages` without one overwriting the other? How do you let a module conditionally enable another module? How do you share config across macOS and NixOS?

The module system solves all of this. It's the reason Nix configs can be split across dozens of files and still produce a coherent result.

**Terraform analogy**: It's like how multiple `.tf` files in the same directory all get merged together. Each file contributes pieces of the final config. The module system is Nix's mechanism for doing this, but with explicit type rules.

---

### What a Module Is

A module is a `.nix` file that follows a specific shape. It's either:

**Form 1 — an attribute set** (simple, uncommon):
```nix
{
  environment.systemPackages = [ pkgs.git ];
}
```

**Form 2 — a function returning an attribute set** (standard):
```nix
{ pkgs, lib, config, ... }:
{
  environment.systemPackages = [ pkgs.git ];
}
```

The function form is standard because the module system passes useful arguments: `pkgs` (the package set), `lib` (utility functions), `config` (the final merged config — used for conditionals), and more.

---

### The Full Module Structure

A module can have three keys: `imports`, `options`, and `config`.

```nix
{ pkgs, lib, config, ... }:
{
  # 1. imports — other modules to load and merge
  imports = [
    ./other-module.nix
    ./another-module.nix
  ];

  # 2. options — declarations of new options (you rarely write these)
  #    This is for when you're creating a reusable module with its own options
  options = {
    myModule.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable my custom module";
    };
  };

  # 3. config — the actual option assignments
  config = {
    environment.systemPackages = [ pkgs.git ];
  };
}
```

**The shorthand** — when you have no `options` block, you can skip the `config` wrapper:

```nix
{ pkgs, ... }:
{
  # This is implicitly under config:
  environment.systemPackages = [ pkgs.git ];
  system.defaults.dock.autohide = true;
}
```

This shorthand is what you'll use 99% of the time. The full form only appears when you're declaring new options.

---

### How Modules Get Called

The module system calls your module function and passes these arguments automatically:

| Argument | What it is |
|---|---|
| `pkgs` | The full nixpkgs package set |
| `lib` | nixpkgs utility functions (`lib.mkIf`, `lib.types`, etc.) |
| `config` | The final merged config (from ALL modules combined) |
| `options` | Option metadata |
| `modulesPath` | Path to the nix-darwin/NixOS modules directory |

This is why `{ pkgs, ... }:` works — you take `pkgs` and let `...` absorb the rest.

---

### How Modules Merge

This is the key mechanic. When multiple modules set the same option, the module system merges them according to the option's type:

**Lists are concatenated:**
```nix
# Module A:
environment.systemPackages = [ pkgs.git ];

# Module B:
environment.systemPackages = [ pkgs.vim ];

# Result:
environment.systemPackages = [ pkgs.git pkgs.vim ];
```

**Scalars (bool, string, int) conflict:**
```nix
# Module A:
system.defaults.dock.autohide = true;

# Module B:
system.defaults.dock.autohide = false;

# → ERROR: "The option ... is defined in multiple places with conflicting values."
# Set each scalar option in exactly ONE module.
```

**Attribute sets are merged recursively:**
```nix
# Module A:
nix.settings = { experimental-features = [ "flakes" ]; };

# Module B:
nix.settings = { max-jobs = 8; };

# Result:
nix.settings = { experimental-features = [ "flakes" ]; max-jobs = 8; };
```

---

### `imports` — Composing Modules

The `imports` key in a module tells the module system to load and merge additional modules:

```nix
{ ... }:
{
  imports = [
    ./system-preferences.nix
    ./packages.nix
    ./homebrew.nix
  ];

  # Options set here are merged with those from the imported modules
  system.stateVersion = 5;
}
```

`imports` is **not a function call** — it's data the module system reads. The module system handles loading and calling each imported module function, passing the same arguments to all of them.

**This is different from `import`** (lowercase, no s). The `import` built-in just loads a file. The `imports` key in a module tells the module system to recursively process a list of modules.

---

### Conditional Configuration with `lib.mkIf`

Because `config` is available as an argument, modules can conditionally apply settings:

```nix
{ config, lib, pkgs, ... }:
{
  # Only install these packages if homebrew is enabled
  environment.systemPackages = lib.mkIf config.homebrew.enable [
    pkgs.mas    # Mac App Store CLI — only useful when homebrew is present
  ];
}
```

`lib.mkIf condition value` — if condition is true, value is used; otherwise this option assignment is ignored.

You won't need to write this immediately, but you'll see it when reading other people's configs.

---

### The Fixed-Point — Why `config` Can Reference Itself

There's something circular-seeming about the module system: `config` (the final result) is passed as an argument to the modules that produce it. How can you compute the result when computing the result requires the result?

The answer is **lazy evaluation**. Nix only computes a value when it's actually needed. The module system sets up a "lazy knot" where `config` is a promise that gets resolved on demand.

In practice, you only need to know: **you can reference `config.something` in a module and it will work, as long as you're not creating a cycle** (e.g., a value defined by itself).

---

### `specialArgs` — Passing Extra Data to All Modules

Sometimes you want to pass data to all modules that isn't one of the standard arguments. For example: your username, the hostname, paths to extra files.

This is done via `specialArgs` in the flake:

```nix
# In flake.nix:
nix-darwin.lib.darwinSystem {
  modules = [ ./hosts/darwin/default.nix ];
  specialArgs = {
    username = "kacper";
    hostname = "kacpers-MacBook-Pro";
  };
}
```

Then any module can receive these:

```nix
# In any module:
{ pkgs, username, hostname, ... }:
{
  home-manager.users.${username} = { ... };
  networking.hostName = hostname;
}
```

This avoids hardcoding your username in every module file.

---

## Exercise: Annotate the Full Module Chain

Given this structure, trace what the final merged config looks like:

**`flake.nix`** passes `modules = [ ./hosts/darwin/default.nix ]`

**`hosts/darwin/default.nix`**:
```nix
{ pkgs, ... }:
{
  imports = [
    ./packages.nix
    ./preferences.nix
  ];
  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";
}
```

**`packages.nix`**:
```nix
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ git vim ];
}
```

**`preferences.nix`**:
```nix
{ ... }:
{
  system.defaults.dock.autohide = true;
  environment.systemPackages = [ ];    # empty — gets merged with packages.nix
}
```

Questions to answer:
1. What is the final value of `environment.systemPackages`?
2. What is the final value of `system.stateVersion`?
3. What is the final value of `system.defaults.dock.autohide`?
4. Which module's `imports` triggers loading of `packages.nix`?

---

## Comprehension Questions

1. **What's the difference between `imports` and `import`?** Write a one-sentence explanation of each.

2. **If two modules both set `system.defaults.dock.autohide = true`, is that an error?** What about if one sets it to `true` and one to `false`?

3. **Why does every module have `...` in `{ pkgs, ... }:`?** List three arguments the module system passes that your module might not use.

4. **What is `specialArgs` for?** Give an example of something you'd pass via `specialArgs` rather than just hardcoding in a module.

5. **In Ansible terms**, what is the module system's merge behavior equivalent to? When two roles both install packages, what happens?

---

## Milestone: Read the Full Config

Before moving to Phase 2, take the existing lesson files (01-06) and read through the `.nix` code snippets in them. You should be able to explain every line. If any syntax is unclear, re-read the relevant P1 lesson.

Specifically, make sure you can explain:
- `{ pkgs, ... }:` — a function, what does it take, what does it return?
- `with pkgs; [ git vim ]` — what does `with` do here?
- `nix-darwin.lib.darwinSystem { ... }` — what is this doing?
- `outputs = { self, nixpkgs, nix-darwin }: { ... }` — function or value?
- `modules = [ ./hosts/darwin/default.nix ]` — what type is this?
- `imports = [ ./packages.nix ]` — how is this different from the above?

If you can answer all of these confidently, you're ready for Phase 2.
