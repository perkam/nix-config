# L2: NixOS Services — Declaring Infrastructure

> **Goal**: Declare and manage real services on your NixOS server. After this lesson, services like Nginx, PostgreSQL, or a VPN will be running and managed entirely through your Nix config.

## Prerequisites

- L1 complete — NixOS machine building successfully

---

## Concepts

### The Ansible-to-NixOS Translation

The mental shift from Ansible to NixOS is direct:

```
Ansible:
  - name: Install nginx
    apt: name=nginx state=present
  - name: Enable and start nginx
    service: name=nginx state=started enabled=yes
  - name: Configure nginx
    template: src=nginx.conf.j2 dest=/etc/nginx/nginx.conf
    notify: restart nginx

NixOS:
  services.nginx.enable = true;
  services.nginx.virtualHosts."myserver.local" = {
    root = "/var/www/html";
  };
  # nginx is installed, started, enabled, and configured.
  # The config file is generated from your Nix options.
  # Rebuilding applies config changes.
```

One option enables the service, installs the package, creates the systemd unit, and generates the config file.

### Available Services

NixOS has modules for hundreds of services. Browse them:

```bash
# On your NixOS machine:
nixos-option services    # tab-complete to see available services

# Or online: https://search.nixos.org/options?query=services.
```

Common ones you might use in a homelab:

| Service | Option prefix |
|---|---|
| Nginx | `services.nginx` |
| PostgreSQL | `services.postgresql` |
| Docker | `virtualisation.docker` |
| WireGuard | `networking.wireguard` |
| Pi-hole equivalent | `services.blocky` |
| Gitea | `services.gitea` |
| Grafana | `services.grafana` |
| Prometheus | `services.prometheus` |
| Tailscale | `services.tailscale` |

---

## Exercise 1: Enable SSH with key-only auth

```nix
# modules/nixos/services.nix
{ ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;    # keys only
      PermitRootLogin = "no";
    };
  };
}
```

## Exercise 2: Add a reverse proxy with Nginx

```nix
services.nginx = {
  enable = true;

  # Serve a static site
  virtualHosts."homelab.local" = {
    root = "/var/www/html";
  };

  # Or proxy to an application
  virtualHosts."app.homelab.local" = {
    locations."/" = {
      proxyPass = "http://localhost:3000";
      proxyWebsockets = true;
    };
  };
};
```

## Exercise 3: Enable Docker

```nix
virtualisation.docker = {
  enable = true;
  autoPrune.enable = true;     # automatically prune unused images
};

# Add your user to the docker group so you don't need sudo
users.users.kacper.extraGroups = [ "wheel" "docker" ];
```

## Exercise 4: Add PostgreSQL

```nix
services.postgresql = {
  enable = true;
  package = pkgs.postgresql_16;

  ensureDatabases = [ "myapp" ];
  ensureUsers = [{
    name = "myapp";
    ensureDBOwnership = true;
  }];
};
```

## Exercise 5: Pick a service you actually want

Add one service relevant to your homelab goals. Browse `https://search.nixos.org/options` for it, read the available options, and declare it in `modules/nixos/services.nix`.

Build and verify it's running:

```bash
nixos-rebuild switch --flake .#homelab

# Check service status
systemctl status nginx
systemctl status postgresql

# Check logs
journalctl -u nginx -f
```

---

## Comprehension Questions

1. **When you add `services.nginx.enable = true` and rebuild**, what does NixOS do? List every action it takes (install, config, systemd, etc.).

2. **What happens if you remove a service from your config and rebuild?** Is it stopped? Uninstalled? Compare this to Ansible's behavior when you remove a task.

3. **How do you find the available options for a service?** Give two ways.

4. **Where does NixOS put generated config files** (like `nginx.conf`)? Can you edit them manually? What happens to manual edits on the next rebuild?

5. **In Ansible terms**, what's the difference between configuring a service in NixOS vs using the `community.general.nginx` Ansible role?
