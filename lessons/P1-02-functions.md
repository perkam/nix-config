# P1-02: Functions

> **Goal**: Understand Nix functions completely — how to define them, call them, and read them in any `.nix` file. Functions are the core abstraction in Nix. Everything is built from them.

## Prerequisites

- P1-01 complete — comfortable with attribute sets and basic types
- `nix repl` open

---

## Concepts

### Functions are First-Class Values

In Nix, functions are values just like strings or numbers. You can store them in variables, put them in lists, pass them as arguments, return them from other functions.

A function in Nix is always: `parameter: body`

That's it. One parameter, a colon, then the body expression.

```nix
# Define a function (it has no name yet — it's anonymous)
x: x * 2

# Store it in a variable
let double = x: x * 2;
in double 5    # → 10

# Call a function: just write the function and the argument next to each other
# No parentheses, no commas
double 5       # → 10
double (3 + 4) # → 14  (parentheses only needed to group expressions)
```

**Key difference from other languages**: There are no parentheses in function calls. `f x` means "call f with x". This trips everyone up at first.

---

### Functions with Attribute Set Arguments

Most Nix functions you'll encounter don't take a simple argument — they take an **attribute set**. This is how Nix simulates named arguments.

```nix
# A function that takes an attribute set with keys name and greeting
{ name, greeting }: "${greeting}, ${name}!"

# Call it by passing an attribute set
({ name, greeting }: "${greeting}, ${name}!") { name = "kacper"; greeting = "Hello"; }
# → "Hello, kacper!"

# Stored and called:
let greet = { name, greeting }: "${greeting}, ${name}!";
in greet { name = "kacper"; greeting = "Hi"; }
# → "Hi, kacper!"
```

This is the pattern you see in every module:

```nix
# This IS a function. It takes a set with pkgs in it.
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.git ];
}
```

---

### The Ellipsis `...`

When you use an attribute set argument, Nix checks that you're not passing any unexpected keys. The ellipsis `...` tells Nix to silently ignore any extra keys.

```nix
# WITHOUT ... — strict, rejects unexpected keys
let f = { a, b }: a + b;
in f { a = 1; b = 2; c = 99; }    # ERROR: unexpected argument 'c'

# WITH ... — permissive, ignores extra keys
let f = { a, b, ... }: a + b;
in f { a = 1; b = 2; c = 99; }    # → 3  (c is ignored)
```

**Why this matters**: The module system calls your module function with many arguments (`pkgs`, `lib`, `config`, `options`, `modulesPath`, etc.). Your module only uses a few of them. The `...` absorbs the rest.

```nix
# Your module only needs pkgs — but the system passes many more arguments
{ pkgs, ... }:    # ← ... absorbs config, lib, options, etc.
{
  environment.systemPackages = [ pkgs.git ];
}
```

---

### Default Values

You can give arguments default values with `?`:

```nix
let greet = { name ? "world", greeting ? "Hello" }: "${greeting}, ${name}!";
in greet {}                          # → "Hello, world!"
in greet { name = "kacper"; }       # → "Hello, kacper!"
in greet { name = "kacper"; greeting = "Hi"; }   # → "Hi, kacper!"
```

You'll see this in package definitions where some inputs are optional.

---

### The `@`-Pattern

Sometimes you want both the individual named arguments AND the whole set. The `@`-pattern gives you both:

```nix
# args is the whole set; pkgs, lib are individual keys
args @ { pkgs, lib, ... }:
{
  # Use pkgs directly
  environment.systemPackages = [ pkgs.git ];

  # Use the whole set to pass to something else
  _module.args = args;
}
```

The `@` can appear on either side:

```nix
{ pkgs, ... } @ args:    # same thing, @ on the right
```

You'll see `inputs @ { self, nixpkgs, ... }:` in flakes — it gives a name (`inputs`) to all the flake inputs while also letting you destructure individual ones.

---

### Calling Functions — No Parentheses

Function application in Nix is left-associative and requires no punctuation:

```nix
f x           # call f with x
f x y         # call (f x) with y — currying
f { a = 1; }  # call f with an attribute set

# These are all equivalent:
nix-darwin.lib.darwinSystem { modules = []; }
# means: access nix-darwin, then .lib, then .darwinSystem, then call it with { modules = []; }

# Parentheses only needed for grouping:
double (3 + 4)    # not: double 3 + 4  (which would mean (double 3) + 4)
```

---

### Currying — Multiple Arguments

Nix functions take exactly one argument. To simulate multiple arguments, you return a function from a function:

```nix
# A "two argument" function — actually a function returning a function
let add = x: y: x + y;
in add 3 4    # → 7

# What's happening:
# add 3       → (y: 3 + y)    -- a new function
# (add 3) 4   → 7             -- that function called with 4

# Partial application — call with just the first argument
let add5 = add 5;    # → (y: 5 + y)
in add5 3             # → 8
```

You'll see currying used to build configuration helpers:

```nix
# A helper that creates a user config with defaults
let mkUser = username: { pkgs, ... }: {
  home.username = username;
  home.homeDirectory = "/Users/${username}";
};
in mkUser "kacper"    # → a function { pkgs, ... }: { ... }
```

---

### Functions as Arguments and Return Values

Since functions are values, you can pass them around:

```nix
# A function that applies another function twice
let applyTwice = f: x: f (f x);
in applyTwice (x: x + 1) 5    # → 7

# map applies a function to each list element (built-in)
map (x: x * 2) [ 1 2 3 4 ]    # → [ 2 4 6 8 ]

# builtins.filter keeps elements where the function returns true
builtins.filter (x: x > 2) [ 1 2 3 4 ]    # → [ 3 4 ]
```

---

## Exercises

**Exercise 1: Define and call functions**
```
nix-repl> let double = x: x * 2; in double 7
nix-repl> let square = x: x * x; in square 5
nix-repl> (x: x + 10) 32
```

**Exercise 2: Attribute set arguments**
```
nix-repl> let f = { a, b }: a + b; in f { a = 3; b = 4; }
nix-repl> let f = { name, ... }: "Hello, ${name}!"; in f { name = "kacper"; extra = "ignored"; }
```

**Exercise 3: Default values**
```
nix-repl> let greet = { name ? "world" }: "Hello, ${name}!"; in greet {}
nix-repl> let greet = { name ? "world" }: "Hello, ${name}!"; in greet { name = "kacper"; }
```

**Exercise 4: Currying**
```
nix-repl> let add = x: y: x + y; in add 3 4
nix-repl> let add = x: y: x + y; in let add5 = add 5; in add5 10
```

**Exercise 5: The @-pattern**
```
nix-repl> let f = all @ { a, b, ... }: all; in f { a = 1; b = 2; c = 3; }
```

**Exercise 6: Read the flake**

Open `flake.nix` (if it exists) or look at this snippet and identify:
- How many functions are defined?
- What does each function take as an argument?
- Where is each function called?

```nix
{
  outputs = { self, nixpkgs, nix-darwin }: {
    darwinConfigurations."kacpers-MacBook-Pro" = nix-darwin.lib.darwinSystem {
      modules = [ ./hosts/darwin/default.nix ];
    };
  };
}
```

---

## Comprehension Questions

1. **What is `{ pkgs, ... }:` on its own?** Is it a value? A statement? What type does it evaluate to?

2. **Why does every module have `...` in its argument?** What would happen if you removed it?

3. **Explain `nix-darwin.lib.darwinSystem { modules = []; }`** in plain English. What is `nix-darwin.lib.darwinSystem`? What does calling it with `{ modules = []; }` produce?

4. **What is the `@`-pattern for?** Write a scenario where you'd need it — where would accessing just the named fields be insufficient?

5. **In Terraform terms**, what is the closest equivalent to a Nix function that takes `{ pkgs, config, lib, ... }:`? Think about HCL modules and their `variable` blocks.
