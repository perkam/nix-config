# P1-01: Values and Attribute Sets

> **Goal**: Understand every value type in the Nix language and read attribute sets fluently. By the end, you'll understand the data side of every `.nix` file you encounter.

## How We'll Work

Open the Nix REPL alongside this lesson. Every concept has an exercise you run immediately.

```bash
nix repl
```

You should see `nix-repl>`. Type expressions and press Enter to evaluate them.

---

## Concepts

### Nix is a Pure Expression Language

Nix has no statements, no loops, no mutation. Everything is an **expression** that evaluates to a value. Think of it like a spreadsheet — cells contain formulas that compute values, not instructions that run in sequence.

This matters because it means:
- You can't change a variable once it's set
- There are no side effects in the language (only in the build system below it)
- The same expression always produces the same value

**Terraform analogy**: HCL expressions (like `var.region` or `"${var.prefix}-server"`) are pure — they compute values, they don't run commands. Nix is like that, but for the entire language.

---

### The Seven Value Types

#### 1. Strings

```nix
"hello world"

# Multi-line strings use double single-quotes
''
  line one
  line two
''

# String interpolation — embed any expression with ${ }
let name = "kacper";
in "Hello, ${name}!"      # → "Hello, kacper!"

# Paths inside strings need toString
"${toString ./some/path}"
```

#### 2. Numbers

```nix
42          # integer
3.14        # float
-7          # negative

# Arithmetic works as expected
1 + 2       # → 3
10 / 3      # → 3  (integer division)
10.0 / 3    # → 3.333...
```

#### 3. Booleans

```nix
true
false

# Logical operators
true && false   # → false
true || false   # → true
!true           # → false
```

#### 4. Null

```nix
null    # represents absence of a value
```

#### 5. Paths

```nix
# Paths are a distinct type — NOT strings
/nix/store/abc123          # absolute path
./relative/to/this/file    # relative path (resolved at parse time)
~/home                     # home-relative path

# This matters: Nix treats paths specially (they get copied to the store)
# Don't confuse paths with path strings like "/some/path"
```

#### 6. Lists

```nix
# Lists use square brackets, NO commas between items
[ 1 2 3 ]
[ "one" "two" "three" ]
[ true false true ]

# Lists can mix types (but this is unusual in practice)
[ 1 "two" true ]

# Empty list
[ ]

# Lists of derivations — the most common use
[ pkgs.git pkgs.vim pkgs.ripgrep ]
```

#### 7. Attribute Sets

This is the most important type in Nix. An attribute set is an unordered collection of key-value pairs — like a dict in Python, an object in JSON, or a map in HCL.

```nix
# Basic attribute set
{
  name = "kacper";
  age = 30;
}

# Values can be any type, including nested sets
{
  name = "kacper";
  address = {
    city = "Warsaw";
    country = "Poland";
  };
  packages = [ "git" "vim" ];
}

# Access values with dot notation
let person = { name = "kacper"; age = 30; };
in person.name     # → "kacper"

# Nested access
let config = { dock = { autohide = true; tilesize = 48; }; };
in config.dock.autohide    # → true
```

---

### The `with` Expression

`with` brings all keys of an attribute set into scope. You'll see it constantly in package lists.

```nix
# Without with — verbose
environment.systemPackages = [ pkgs.git pkgs.vim pkgs.ripgrep pkgs.bat ];

# With with — pkgs is "opened", its keys are directly accessible
environment.systemPackages = with pkgs; [ git vim ripgrep bat ];

# They're identical. with pkgs; means:
# "for names in this expression, look them up in pkgs if not found locally"
```

**Ansible analogy**: Like `with_items` — it brings a collection into the current scope so you don't have to prefix every reference.

---

### The `rec` Keyword

`rec` makes an attribute set self-referential — keys can reference other keys in the same set.

```nix
# Without rec — this would fail (name not in scope)
{ name = "hello"; greeting = "Hi, ${name}"; }    # ERROR

# With rec — keys can reference each other
rec { name = "hello"; greeting = "Hi, ${name}"; }
# → { name = "hello"; greeting = "Hi, hello"; }
```

You'll see `rec` occasionally in package definitions. It's a special case — most sets don't need it.

---

### Attribute Set Operators

```nix
# Merge two sets with //
{ a = 1; b = 2; } // { b = 99; c = 3; }
# → { a = 1; b = 99; c = 3; }
# Right side wins on conflicts

# Check if a key exists
{ a = 1; } ? a    # → true
{ a = 1; } ? b    # → false

# Access with a default (in case key doesn't exist)
{ a = 1; }.b or "default"    # → "default"
```

---

### `inherit` — Reducing Repetition

`inherit` is shorthand for "copy this name from the surrounding scope":

```nix
let
  name = "kacper";
  age = 30;
in {
  # Without inherit:
  name = name;    # tedious
  age = age;

  # With inherit:
  inherit name age;    # same result, less repetition
}
```

You'll see `inherit` a lot in flakes and nixpkgs.

---

## Exercises

Work through these in `nix repl`. Type each expression and check your prediction.

**Exercise 1: Basic types**
```
nix-repl> "hello" + " " + "world"
nix-repl> 10 / 3
nix-repl> 10.0 / 3
nix-repl> true && false
nix-repl> [ 1 2 3 ]
```

**Exercise 2: Attribute sets**
```
nix-repl> { a = 1; b = 2; }
nix-repl> { a = 1; b = 2; }.a
nix-repl> let x = { name = "kacper"; city = "Warsaw"; }; in x.city
nix-repl> { a = 1; b = 2; } // { b = 99; c = 3; }
```

**Exercise 3: with**
```
nix-repl> with { git = "the-git-package"; vim = "the-vim-package"; }; [ git vim ]
```

**Exercise 4: String interpolation**
```
nix-repl> let name = "kacper"; in "Hello, ${name}!"
nix-repl> let n = 42; in "The answer is ${toString n}"
```

**Exercise 5: Nested sets**
```
nix-repl> let config = { dock = { autohide = true; tilesize = 48; }; }; in config.dock.tilesize
nix-repl> let s = { a = 1; b = { c = 2; }; }; in s.b.c
```

**Exercise 6: inherit**
```
nix-repl> let name = "kacper"; age = 30; in { inherit name age; }
```

---

## Comprehension Questions

Answer these before moving on:

1. **What's the difference between `[ "one" "two" ]` and `{ a = "one"; b = "two"; }`?** When would you use a list vs. an attribute set?

2. **What does `with pkgs; [ git vim ]` evaluate to?** If `pkgs` is `{ git = <derivation>; vim = <derivation>; }`, write out what the list contains without using `with`.

3. **What does `//` do?** If `a = { x = 1; y = 2; }` and `b = { y = 99; z = 3; }`, what is `a // b`?

4. **In Terraform terms**, what is an attribute set? What's the equivalent construct in HCL?

5. **Why does Nix have paths as a separate type** (not just strings)? What's special about `./some/file` vs `"./some/file"`?
