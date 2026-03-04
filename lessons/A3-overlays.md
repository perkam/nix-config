# A3: Overlays — System-Wide Package Modifications

> **Goal**: Use nixpkgs overlays to modify packages globally, add packages not in nixpkgs, and maintain a clean package set across your entire config.

## When to Start This Lesson

Start this when you need to:
- Modify a package that's used as a dependency by other packages (so dependents use your version)
- Maintain a set of custom packages across your entire system
- Add packages not in nixpkgs in a structured way

---

## Concepts

### What is an Overlay?

An overlay is a function that takes `final` and `prev` and returns modifications to the nixpkgs package set:

```nix
final: prev: {
  # Add or replace packages here
}
```

- `prev` — the package set before this overlay (the "previous" state)
- `final` — the package set after ALL overlays are applied (for cross-overlay references)

**The simple mental model**: `prev` is what nixpkgs normally gives you. Your overlay returns a set of modifications. The result is nixpkgs with your modifications applied.

### A Simple Overlay

```nix
# In nixpkgs.overlays or in a flake:
nixpkgs.overlays = [
  (final: prev: {
    # Override an existing package globally
    ripgrep = prev.ripgrep.overrideAttrs (old: {
      doCheck = false;
    });

    # Add a new package that isn't in nixpkgs
    my-tool = final.callPackage ./packages/my-tool/default.nix { };

    # Add a modified version alongside the original
    ripgrep-no-tests = prev.ripgrep.overrideAttrs (old: {
      doCheck = false;
    });
  })
];
```

### `final` vs `prev` — When to Use Each

```nix
(final: prev: {
  # Use prev when building something FROM nixpkgs
  # (it avoids infinite recursion — you're not referencing yourself)
  vim = prev.vim.overrideAttrs (old: { ... });

  # Use final when your new package needs OTHER packages from the overlay
  # (so it gets the overlay-modified versions)
  myBundle = final.callPackage ./bundle.nix {
    # uses final.ripgrep (the overlay version) instead of prev.ripgrep
    ripgrep = final.ripgrep;
  };
})
```

**Rule of thumb**: use `prev` for overriding existing packages, `final` for new packages that might depend on other overlay packages.

### Where Overlays Live

**Option 1: In your nix-darwin module** (simplest):

```nix
# In any module:
{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      my-tool = final.callPackage ../packages/my-tool { };
    })
  ];
}
```

**Option 2: As a separate file** (cleaner for multiple overlays):

```nix
# modules/overlays.nix
{ ... }:
{
  nixpkgs.overlays = [
    (import ../overlays/my-tool.nix)
    (import ../overlays/modifications.nix)
  ];
}
```

```nix
# overlays/my-tool.nix
final: prev: {
  my-tool = final.callPackage ../packages/my-tool { };
}
```

---

## Exercise 1: Add a custom package via overlay

Pick a tool you use that isn't in nixpkgs (or pretend one isn't). Write a package definition and add it via an overlay:

```nix
# modules/overlays.nix
{ ... }:
{
  nixpkgs.overlays = [
    (final: prev: {
      my-custom-tool = final.callPackage ../packages/my-custom-tool { };
    })
  ];
}
```

Add this module to your `imports` and the tool to `environment.systemPackages`:

```nix
environment.systemPackages = [ pkgs.my-custom-tool ];
```

## Exercise 2: Modify a package globally

If you find a package that fails tests on macOS:

```nix
nixpkgs.overlays = [
  (final: prev: {
    somePackage = prev.somePackage.overrideAttrs (old: {
      doCheck = false;
    });
  })
];
```

Now every package that depends on `somePackage` — not just yours — gets the fixed version.

---

## Comprehension Questions

1. **What's the difference between using `.overrideAttrs` in `environment.systemPackages` vs in an overlay?** Which approach affects packages that depend on the modified one?

2. **When should you use `final` vs `prev` in an overlay?** What goes wrong if you use `final` everywhere?

3. **Can you have multiple overlays?** How are they composed? Does the order matter?

4. **What is `callPackage` in an overlay** — is it the same as `pkgs.callPackage` or something different?

5. **You have a patched version of openssl.** If you put it in an overlay, does curl (which depends on openssl) automatically use your patched version? Why or why not?
