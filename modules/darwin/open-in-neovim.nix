{ username, pkgs, ... }:
let
  # AppleScript that opens files in Neovim via Ghostty
  # Uses Ghostty's native AppleScript API (requires Ghostty 1.3.0+)
  # - "on run" handles launching from Spotlight or double-click (opens nvim in home dir)
  # - "on open" handles files passed via "Open With" or drag-and-drop
  openInNeovimScript = pkgs.writeText "neovim.applescript" ''
    -- Launch from Spotlight or double-click: open nvim in home directory
    on run
        set homeDir to POSIX path of (path to home folder)
        
        tell application "Ghostty"
            activate
            set cfg to new surface configuration
            set initial working directory of cfg to homeDir
            set win to new window with configuration cfg
            set t to terminal 1 of selected tab of win
            input text "nvim" to t
            send key "enter" to t
        end tell
    end run
    
    -- Open With / drag-and-drop: open nvim with the files
    on open theFiles
        set file_list to ""
        set workingDir to ""
        
        repeat with theFile in theFiles
            set filePath to POSIX path of theFile
            set file_list to file_list & " " & quoted form of filePath
            
            -- Set working directory to parent of first file
            if workingDir is "" then
                set workingDir to do shell script "dirname " & quoted form of filePath
            end if
        end repeat
        
        tell application "Ghostty"
            activate
            set cfg to new surface configuration
            set initial working directory of cfg to workingDir
            set win to new window with configuration cfg
            set t to terminal 1 of selected tab of win
            input text "nvim" & file_list to t
            send key "enter" to t
        end tell
    end open
  '';

  neovimIcon = ./neovim.icns;
in
{
  home-manager.users.${username} = { lib, ... }: {
    # Activation script to build and install the app
    # We build during activation because osacompile requires macOS system tools
    # that aren't available in the Nix sandbox
    home.activation.installOpenInNeovim =
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        APP_PATH="$HOME/Applications/Neovim.app"
        SCRIPT_PATH="${openInNeovimScript}"
        ICON_PATH="${neovimIcon}"
        
        # Create Applications directory if it doesn't exist
        mkdir -p "$HOME/Applications"
        
        # Remove old versions if they exist
        rm -rf "$APP_PATH"
        rm -rf "$HOME/Applications/OpenInNeovim.app"
        
        # Compile the AppleScript into an app bundle
        # osacompile is a macOS system tool, not available in Nix sandbox
        /usr/bin/osacompile -o "$APP_PATH" "$SCRIPT_PATH"
        
        # Replace the default Automator icon with Neovim icon
        cp "$ICON_PATH" "$APP_PATH/Contents/Resources/applet.icns"
        
        # Touch to update Launch Services database
        touch "$APP_PATH"
      '';
  };
}
