{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # LSP servers, formatters, and tools installed via nix (no Mason needed)
    extraPackages = with pkgs; [
      # LSP servers
      lua-language-server # Lua
      nixd # Nix
      nodePackages.typescript-language-server # JavaScript/TypeScript
      pyright # Python
      bash-language-server # Bash
      terraform-ls # Terraform
      gopls # Go
      omnisharp-roslyn # C#

      # Formatters & linters
      stylua # Lua formatter
      prettierd # JS/TS/JSON/YAML/MD formatter
      black # Python formatter
      ruff # Python linter/formatter
      shfmt # Shell formatter
      shellcheck # Shell linter
      gofumpt # Go formatter
      gotools # Go tools (goimports)
      csharpier # C# formatter
      nixfmt-classic # Nix formatter

      # Tools needed by plugins
      ripgrep
      fd
      tree-sitter
      nmap # Provides ncat for Godot LSP connection
    ];
  };

  # Symlink the nvim config directory
  home.file.".config/nvim" = {
    source = ./nvim;
    recursive = true;
  };
}
