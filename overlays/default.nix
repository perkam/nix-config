# Custom overlays for package modifications
#
# Usage in lib/default.nix:
#   pkgs = import inputs.nixpkgs {
#     inherit system;
#     overlays = import ../overlays { inherit inputs; };
#   };
#
# Examples:
#
# Pin a package to a specific version:
#   (final: prev: {
#     foo = prev.foo.overrideAttrs (old: {
#       version = "1.2.3";
#       src = prev.fetchFromGitHub { ... };
#     });
#   })
#
# Use a package from a different nixpkgs:
#   (final: prev: {
#     foo = inputs.nixpkgs-unstable.legacyPackages.${prev.system}.foo;
#   })
#
# Add a custom package:
#   (final: prev: {
#     my-script = prev.writeShellScriptBin "my-script" ''
#       echo "Hello, world!"
#     '';
#   })

{ inputs }:

[
  # Disable direnv tests - fish shell test fails on macOS sandbox
  (final: prev: {
    direnv = prev.direnv.overrideAttrs (old: {
      doCheck = false;
    });
  })
]
