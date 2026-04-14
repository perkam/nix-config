{ ... }: {
  launchd.agents.obsidian = {
    enable = true;
    config = {
      ProgramArguments = [ "/usr/bin/open" "-a" "Obsidian" ];
      RunAtLoad = true;
    };
  };

  launchd.agents.spotify = {
    enable = true;
    config = {
      ProgramArguments = [ "/usr/bin/open" "-a" "Spotify" ];
      RunAtLoad = true;
    };
  };
}
