# P1-03: `let`, `if`, and Loading Files

> **Goal**: Understand the remaining Nix language constructs — `let...in` for local bindings, `if...then...else` for conditionals, and `import` for loading other files. After this lesson, you'll have seen all the syntax that appears in real configs.

## Prerequisites

- P1-01 and P1-02 complete
- `nix repl` open

---

## Concepts

### `let...in` — Local Variable Bindings

`let...in` is how you define names local to an expression. Think of it as defining temporary variables that exist only within the `in` block.

```nix
let
  x = 10;
  y = 20;
in
  x + y    # → 30
```

The structure is always:
- `let` — opens the binding block
- One or more `name = expression;` bindings
- `in` — closes the binding block
- One expression that uses those bindings — this is the value the whole thing evaluates to

**The binding block ends with `in`.** The `in` expression is the return value. You cannot use `x` or `y` outside of the `in` expression.

```nix
# Bindings can reference each other (but not circularly)
let
  base = 10;
  doubled = base * 2;    # can use base
  message = "Value is ${toString doubled}";
in
  message    # → "Value is 20"
```

**Real-world example** — you'll see this constantly in flakes:

```nix
outputs = { self, nixpkgs, nix-darwin }:
  let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in
  {
    darwinConfigurations."kacpers-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/darwin/default.nix ];
    };

    # pkgs is available here because we're inside the "in" expression
    packages.${system}.default = pkgs.hello;
  };
```

**Nesting** — `let...in` can be nested:

```nix
let
  x = 10;
in
  let
    y = x * 2;    # x is in scope
  in
    x + y    # → 30
```

**Terraform analogy**: `let` is like `locals {}` in Terraform — it creates named references you can use within the current scope.

---

### `if...then...else` — Conditionals

Nix `if` is an **expression**, not a statement. It always evaluates to a value. Both branches must be present.

```nix
if true then "yes" else "no"    # → "yes"

let isDark = true;
in if isDark then "Dark Mode" else "Light Mode"    # → "Dark Mode"
```

**Both branches are required** because `if` must produce a value — there's no "if without a result". This is different from Python/JS where you can have an `if` with no `else`.

```nix
# ERROR — missing else
if someCondition then doSomething    # ← Nix doesn't allow this

# Correct
if someCondition then doSomething else null
```

**Where you'll see this in practice**:

```nix
# Platform-conditional packages
buildInputs = if stdenv.isDarwin
  then [ darwin.apple_sdk.frameworks.CoreServices ]
  else [ ];

# Conditional option values
system.defaults.dock.autohide = if workMode then true else false;

# Inline boolean coercion (common shortcut)
nix-homebrew.enable = true;
```

**Nested conditionals** — valid but consider using a `let` instead:

```nix
let
  size = if isRetina then "large" else if isTablet then "medium" else "small";
in
  size
```

---

### `import` — Loading Other Files

`import` evaluates a Nix file and returns its value. If the file contains a function (which most `.nix` files do), `import` gives you back that function.

```nix
# If ./config.nix contains: { name = "kacper"; }
import ./config.nix    # → { name = "kacper"; }

# If ./module.nix contains: { pkgs, ... }: { ... }
import ./module.nix    # → a function (not called yet!)

# You'd need to call it:
(import ./module.nix) { pkgs = pkgs; }
```

**This is different from the module system's `imports = [ ]`**. The `imports` key in a module is handled by the module system, which calls your imported functions automatically with the right arguments. When you write `import` yourself, you have to call the function manually.

**The `import` + call pattern** — used when bootstrapping nixpkgs:

```nix
# A common pattern in older (pre-flake) Nix code:
let
  pkgs = import <nixpkgs> { system = "aarch64-darwin"; };
in
  pkgs.git
```

With flakes, you usually get `pkgs` from the flake inputs instead, but you'll still see `import` in many files.

---

### `builtins` — Built-in Functions

Nix has a set of built-in functions available as `builtins.*`. You'll encounter these when reading nixpkgs or advanced configs:

```nix
builtins.toString 42           # → "42"
builtins.length [ 1 2 3 ]      # → 3
builtins.map (x: x*2) [1 2 3]  # → [2 4 6]
builtins.filter (x: x>1) [1 2 3]  # → [2 3]
builtins.attrNames { a=1; b=2; }  # → ["a" "b"]
builtins.hasAttr "a" { a=1; }     # → true
builtins.currentSystem         # → "aarch64-darwin" (your current system)
```

Many are also available without the `builtins.` prefix: `toString`, `map`, `import`, `derivation`.

---

### Putting It Together — Reading a Real Module

With P1-01, P1-02, and P1-03 under your belt, you can now read a complete module file:

```nix
# hosts/darwin/default.nix

{ pkgs, ... }:             # ← function taking an attr set (P1-02)

let                        # ← local bindings (P1-03)
  myPackages = with pkgs; [ git vim ripgrep ];   # with (P1-01), list (P1-01)
in

{                          # ← the return value: an attribute set (P1-01)

  environment.systemPackages = myPackages;    # ← using the let binding

  system.defaults.dock.autohide = true;       # ← nested attr access (P1-01)

  nix.settings.experimental-features =       # ← list value (P1-01)
    [ "nix-command" "flakes" ];

  nixpkgs.hostPlatform = "aarch64-darwin";    # ← string value (P1-01)

  system.stateVersion = 5;                   # ← number value (P1-01)
}
```

Every single line is explainable with concepts from P1-01 through P1-03.

---

## Exercises

**Exercise 1: `let...in`**
```
nix-repl> let x = 5; y = 10; in x + y
nix-repl> let base = 100; pct = 0.15; in base * pct
nix-repl> let greeting = "Hello"; name = "kacper"; in "${greeting}, ${name}!"
```

**Exercise 2: `if...then...else`**
```
nix-repl> if 5 > 3 then "yes" else "no"
nix-repl> let x = 10; in if x > 5 then "big" else "small"
nix-repl> let platform = "darwin"; in if platform == "darwin" then "macOS" else "Linux"
```

**Exercise 3: Combining `let` and `if`**
```
nix-repl> let isDark = true; theme = if isDark then "dark" else "light"; in "Using ${theme} theme"
```

**Exercise 4: `builtins`**
```
nix-repl> builtins.length [ "a" "b" "c" ]
nix-repl> builtins.attrNames { name = "kacper"; city = "Warsaw"; }
nix-repl> builtins.currentSystem
nix-repl> builtins.toString 42
```

**Exercise 5: Read and annotate**

Read this snippet. For each line, identify which P1 lesson concept it uses:

```nix
outputs = { self, nixpkgs, nix-darwin, nix-homebrew }:
let
  system = "aarch64-darwin";
in
{
  darwinConfigurations."kacpers-MacBook-Pro" = nix-darwin.lib.darwinSystem {
    modules = [ ./hosts/darwin/default.nix ];
  };
}
```

Write comments explaining each line before moving to P1-04.

---

## Comprehension Questions

1. **What does `let x = 5; in x + 10` evaluate to?** Can you use `x` outside the `in` expression? Why or why not?

2. **Why does Nix require an `else` branch in every `if`?** What would it mean to have an `if` with no `else` in a purely functional language?

3. **What's the difference between `import ./module.nix` and `imports = [ ./module.nix ]`?** In what situation would you use each?

4. **In Terraform terms**, what's the equivalent of `let...in`? (Hint: think about how you define reusable expressions in HCL without creating full variables.)

5. **Look at this expression** — what does it evaluate to, and why?
   ```nix
   let
     makeGreeting = name: "Hello, ${name}!";
     names = [ "Alice" "Bob" "kacper" ];
   in
     map makeGreeting names
   ```
