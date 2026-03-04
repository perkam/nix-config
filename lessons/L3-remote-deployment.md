# L3: Remote Deployment — Managing Servers from Your Laptop

> **Goal**: Apply NixOS configurations to remote machines from your Mac. Make a change locally, push it, and have the server updated — no SSH-and-manually-edit workflow.

## Prerequisites

- L2 complete — services running on NixOS
- SSH access to your NixOS machine

---

## Concepts

### The Deployment Model

With NixOS, you don't SSH into a server and run commands. You declare the desired state on your laptop, and a tool applies it remotely:

```
Edit .nix file on your Mac
  → commit to git
  → run deployment command
  → Nix builds the new system derivation (locally or on the server)
  → pushes the result to the server's /nix/store/
  → server switches to the new generation
  → can rollback: nixos-rebuild --rollback on the server
```

```
Terraform analogy:
  nixos-rebuild --target-host  →  terraform apply with a remote backend
  flake.lock                   →  terraform.lock.hcl
  nixos-rebuild --rollback     →  terraform state rollback (but automatic and instant)
```

### Option 1: `nixos-rebuild --target-host` (built-in, simplest)

```bash
# On your Mac, deploy to a remote machine:
nixos-rebuild switch \
  --flake .#homelab \
  --target-host kacper@192.168.1.100 \
  --use-remote-sudo

# What this does:
# 1. Evaluates your flake locally
# 2. Builds the system derivation (locally by default)
# 3. Copies the result to the remote /nix/store/ via SSH
# 4. Runs activation on the remote machine
```

**Requirements**: SSH access, your public key in `users.users.kacper.openssh.authorizedKeys.keys`.

**Build on the remote instead** (for underpowered Macs or when the server is faster):
```bash
nixos-rebuild switch \
  --flake .#homelab \
  --target-host kacper@192.168.1.100 \
  --build-host kacper@192.168.1.100 \
  --use-remote-sudo
```

### Option 2: `deploy-rs` (flake-native, recommended for multiple machines)

`deploy-rs` is a deployment tool designed for Nix flakes. Better than `nixos-rebuild --target-host` when you have multiple servers.

```nix
# In flake.nix, add deploy-rs:
inputs.deploy-rs.url = "github:serokell/deploy-rs";

# Add deploy configuration alongside your nixosConfigurations:
deploy.nodes.homelab = {
  hostname = "192.168.1.100";
  profiles.system = {
    user = "root";
    path = deploy-rs.lib.x86_64-linux.activate.nixos
      self.nixosConfigurations.homelab;
  };
};
```

```bash
# Deploy:
nix run github:serokell/deploy-rs -- .#homelab
```

### Option 3: Pull-based deployment (for production)

Instead of pushing from your laptop, the server pulls its own config on a schedule:

```nix
# On the NixOS server, add an auto-upgrade service:
system.autoUpgrade = {
  enable = true;
  flake = "github:yourusername/nix-config#homelab";
  dates = "04:00";        # upgrade at 4am
  allowReboot = false;    # or true if you want auto-reboots
};
```

This pulls from your public GitHub repo and applies automatically. The server manages itself.

---

## Exercise 1: Deploy with `nixos-rebuild --target-host`

From your Mac:

```bash
# Test connectivity first
ssh kacper@<your-server-ip> echo "hello"

# Deploy
nixos-rebuild switch \
  --flake .#homelab \
  --target-host kacper@<your-server-ip> \
  --use-remote-sudo

# Verify the deployment
ssh kacper@<your-server-ip> darwin-rebuild --list-generations
# (on NixOS it's nixos-rebuild --list-generations)
ssh kacper@<your-server-ip> nixos-rebuild --list-generations
```

## Exercise 2: Make a change and deploy

Make a visible change (add a package, change a service config), commit, and redeploy:

```bash
# Add a package to modules/shared/packages.nix
# git add -A && git commit -m "add cowsay"

nixos-rebuild switch \
  --flake .#homelab \
  --target-host kacper@<your-server-ip> \
  --use-remote-sudo

# Verify the change applied:
ssh kacper@<your-server-ip> which cowsay
```

## Exercise 3: Test rollback

On the server, roll back to the previous generation:

```bash
ssh kacper@<your-server-ip>
sudo nixos-rebuild --rollback
# Verify the change is gone
exit
```

---

## Comprehension Questions

1. **Where does the build happen by default with `nixos-rebuild --target-host`?** On your Mac or the server? What are the tradeoffs of each?

2. **What SSH access is required for remote deployment?** What would you need to set up if the server only allows key auth?

3. **What is the pull-based approach (`system.autoUpgrade`) good for?** When would you prefer it over push-based deployment?

4. **After a rollback, what happened to the newer generation?** Is it deleted or still available?

5. **In Terraform terms**, what is remote deployment with NixOS most similar to? What's the equivalent of the `flake.lock` in ensuring the server gets the exact same state you tested locally?
