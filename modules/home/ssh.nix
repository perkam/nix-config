# SSH client configuration
{ ... }: {
  programs.ssh = {
    enable = true;

    # Global defaults for all connections
    serverAliveInterval = 60;   # send keepalive every 60s (avoids dropped idle connections)
    serverAliveCountMax = 3;    # drop after 3 missed keepalives (~3 min)
    compression = true;         # compress traffic (helpful on slow/VPN links)
    addKeysToAgent = "yes";     # auto-load keys into ssh-agent on first use

    matchBlocks = {
      homelab = {
        hostname = "192.168.0.134";
      };
    };
  };
}
