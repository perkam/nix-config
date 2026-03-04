# D3: Development Shells — Per-Project Environments

> **Goal**: Use `nix develop` to create reproducible per-project development environments. This replaces `virtualenv`, `rbenv`, `nvm`, `tfenv`, and every other version manager — with one tool, for any language.

## Prerequisites

- D2 complete — modular config working
- Familiar with the flake `outputs` structure

---

## Concepts

### The Problem with Global Tools

Right now your system packages include everything you work with — multiple versions of different languages, all in the same environment. This causes conflicts and makes it hard to pin versions per project.

```
The old way:
  pyenv install 3.11.0
  rbenv install 3.2.0
  nvm install 18
  tfenv install 1.5.0
  # Now pray they don't conflict
```

### The Nix Solution: `devShells`

A `devShell` is a derivation that produces a development environment. When you run `nix develop`, it builds that derivation and drops you into a shell with exactly those tools, at exactly those versions, isolated from your system.

When you exit the shell, the tools are gone from your PATH. No global pollution.

```bash
# No Python 3.12 globally
python3 --version   # → command not found

# Enter the project shell
nix develop
python3 --version   # → Python 3.12.x  (only in this shell)
exit

# Gone again
python3 --version   # → command not found
```

### `devShell` in a Flake

A `devShell` is added to your flake's outputs. Each project has its own `flake.nix`:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        pkgs.python312
        pkgs.poetry
        pkgs.postgresql
      ];

      shellHook = ''
        echo "Python dev environment ready"
        export DATABASE_URL="postgresql://localhost/myapp_dev"
      '';
    };
  };
}
```

**New syntax**: `let system = "aarch64-darwin"; pkgs = ...; in { ... }` — you now understand this from P1-03. It's `let...in` binding two names for use in the outputs.

`legacyPackages.${system}` is the standard way to get the full nixpkgs package set for your platform in a flake.

---

## Exercise 1: Create a dev shell for a project

Pick a project you're working on. Create `flake.nix` in it:

**Python project:**
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        python312
        python312Packages.pip
        poetry
      ];

      shellHook = ''
        echo "Python $(python3 --version) ready"
      '';
    };
  };
}
```

**Terraform/infrastructure project:**
```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
  let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        terraform
        awscli2
        kubectl
        helm
        jq
      ];
    };
  };
}
```

Then:
```bash
cd your-project
git init
git add flake.nix
nix develop
# You're now in the dev shell with those tools
```

## Exercise 2: Automate with `direnv`

Running `nix develop` manually every time you `cd` into a project is tedious. `direnv` automates this.

You already installed `direnv` in M3. Now:

**1. Add shell integration to Home Manager** (in your `programs.zsh` block):
```nix
programs.zsh = {
  # ... existing config ...
  initExtra = ''
    eval "$(direnv hook zsh)"
  '';
};
```

Or if you use the Home Manager module for direnv:
```nix
programs.direnv = {
  enable = true;
  nix-direnv.enable = true;    # faster nix-develop integration
};
```

**2. Add a `.envrc` to each project:**
```bash
echo "use flake" > .envrc
direnv allow
```

Now every time you `cd` into the project, the dev shell activates automatically. When you leave, it deactivates.

## Exercise 3: Multiple shells in one flake

A flake can have multiple named dev shells:

```nix
devShells.${system} = {
  default = pkgs.mkShell { buildInputs = [ pkgs.python312 ]; };
  test    = pkgs.mkShell { buildInputs = [ pkgs.python312 pkgs.pytest ]; };
  docs    = pkgs.mkShell { buildInputs = [ pkgs.python312 pkgs.sphinx ]; };
};
```

```bash
nix develop              # default shell
nix develop .#test       # test shell
nix develop .#docs       # docs shell
```

---

## Comprehension Questions

1. **What is a `devShell` output?** Is it a derivation? What does `nix develop` do with it?

2. **How is `nix develop` different from `nix shell nixpkgs#python312`?** When would you use each?

3. **What does `shellHook` do?** Can you run arbitrary code there? Give an example of something useful to put in a `shellHook`.

4. **Why is `direnv` + `nix-direnv` useful?** What problem does it solve compared to running `nix develop` manually?

5. **In Terraform terms**, is a `devShell` closer to a Terraform workspace, a module, or something else? What's the "desired state" being declared?
