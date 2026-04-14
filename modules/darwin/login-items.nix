{ ... }: {
  launchd.agents.obsidian = {
    serviceConfig = {
      ProgramArguments = [ "/usr/bin/open" "-a" "Obsidian" ];
      RunAtLoad = true;
    };
  };

  launchd.agents.spotify = {
    serviceConfig = {
      ProgramArguments = [ "/usr/bin/open" "-a" "Spotify" ];
      RunAtLoad = true;
    };
  };
}
