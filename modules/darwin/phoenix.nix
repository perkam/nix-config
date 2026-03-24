{ username, pkgs, ... }: {
  # Phoenix window manager configuration
  # Based on https://github.com/fabiospampinato/phoenix
  
  home-manager.users.${username} = { lib, ... }: {
    # Symlink the Phoenix configuration directory to ~/.config/phoenix
    home.file.".config/phoenix" = {
      source = ./phoenix;
      recursive = true;
    };

    # Store the Karabiner rules for import (makes them visible in Karabiner GUI)
    home.file.".config/karabiner/assets/complex_modifications/phoenix-keys.json" = {
      source = ./phoenix/config/karabiner.json;
    };

    # Activation script to import the Karabiner rules
    home.activation.karabinerPhoenixKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      RULES_FILE="${./phoenix/config/karabiner.json}" \
      JQ="${pkgs.jq}/bin/jq" \
      bash ${./phoenix/scripts/setup-karabiner.sh}
    '';
  };
}
