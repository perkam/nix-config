# L4: Secrets Management with agenix

> **Goal**: Store encrypted secrets in your git repository that decrypt automatically on your machines. After this lesson, database passwords, API keys, and private certificates are part of your declarative config — safely encrypted.

## Prerequisites

- L2 complete — services running that need credentials
- SSH key pair (you already have one if SSH works)

---

## Concepts

### The Problem

Your NixOS config is in git. That's great for reproducibility. But services need secrets: database passwords, API keys, SSL private keys. You can't commit these in plaintext.

### The agenix Approach

`agenix` (based on `age` encryption) solves this by:
1. Encrypting secret files with your SSH public keys
2. Storing the encrypted files in git (safe — only readable by your keys)
3. Decrypting them at activation time using the machine's SSH private key

The private key never leaves the machine. The encrypted file in git is useless without it.

### How It Works

```
Your SSH public key (safe to share, in your git repo):
  ~/.ssh/id_ed25519.pub

agenix encrypts secrets.yaml with your public key
  → secrets/postgresql-password.age  (encrypted, committed to git)

On the server, agenix decrypts it using:
  /etc/ssh/ssh_host_ed25519_key  (the server's private key, never leaves server)
  → /run/agenix/postgresql-password  (decrypted, readable only by the right user)
```

---

## Setup

### Step 1: Add agenix to your flake

```nix
inputs.agenix.url = "github:ryantm/agenix";
inputs.agenix.inputs.nixpkgs.follows = "nixpkgs";

# Add to your NixOS modules:
nixosConfigurations."homelab" = nixpkgs.lib.nixosSystem {
  modules = [
    ./hosts/homelab/default.nix
    agenix.nixosModules.default
  ];
};
```

### Step 2: Create `secrets/secrets.nix` — key declarations

This file tells agenix which public keys can decrypt each secret:

```nix
# secrets/secrets.nix
let
  # Your laptop's SSH public key
  kacper = "ssh-ed25519 AAAA...your-public-key...";

  # Your server's SSH host key (get it with: ssh-keyscan homelab)
  homelab = "ssh-ed25519 AAAA...server-host-key...";
in
{
  # Each secret: which keys can decrypt it
  "postgresql-password.age".publicKeys = [ kacper homelab ];
  "api-key.age".publicKeys = [ kacper homelab ];
}
```

### Step 3: Create secrets

```bash
# From your nix-config directory:
cd secrets/

# Create a secret interactively:
agenix -e postgresql-password.age
# Your editor opens — type the secret, save, close

# The .age file is now encrypted. Commit it:
git add postgresql-password.age
git commit -m "add encrypted postgresql password"
```

### Step 4: Use secrets in NixOS modules

```nix
# modules/nixos/services.nix
{ config, ... }:
{
  # Declare which secrets to decrypt on this machine
  age.secrets.postgresql-password = {
    file = ../../secrets/postgresql-password.age;
    owner = "postgres";    # which user can read the decrypted file
    mode = "0400";
  };

  # Use the decrypted secret path in your service config
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_16;

    # The secret is available at config.age.secrets.postgresql-password.path
    # which resolves to something like /run/agenix/postgresql-password
    initialScript = pkgs.writeText "init.sql" ''
      CREATE ROLE myapp WITH LOGIN PASSWORD '$(cat ${config.age.secrets.postgresql-password.path})';
    '';
  };
}
```

---

## Exercise 1: Create your first secret

```bash
# Install agenix temporarily
nix shell github:ryantm/agenix

# Create the secrets directory
mkdir -p secrets

# Write the key declarations
cat > secrets/secrets.nix << 'EOF'
let
  kacper = "ssh-ed25519 AAAA...";  # paste your ~/.ssh/id_ed25519.pub
  homelab = "ssh-ed25519 AAAA..."; # paste from: ssh-keyscan your-server-ip
in
{
  "test-secret.age".publicKeys = [ kacper homelab ];
}
EOF

# Create an encrypted secret
cd secrets
agenix -e test-secret.age
# Type: hello-secret
# Save and close

# Verify it's encrypted
cat test-secret.age    # should be binary/base64 garbage
```

## Exercise 2: Use a secret in a service

Add a real secret (like a database password or API key) to a service you've configured in L2.

## Exercise 3: Rotate a secret

```bash
# Edit an existing secret
cd secrets
agenix -e postgresql-password.age
# Change the value, save

# Commit and deploy
git add postgresql-password.age
git commit -m "rotate postgresql password"
nixos-rebuild switch --flake .#homelab --target-host kacper@homelab
```

---

## Comprehension Questions

1. **Why is it safe to commit `.age` files to a public git repo?** What would an attacker need to decrypt them?

2. **What is the difference between your SSH key and the server's SSH host key?** Why does agenix use both?

3. **What does `age.secrets.postgresql-password.path` resolve to?** Where is the decrypted file? Who can read it?

4. **What happens to secrets during a `nixos-rebuild switch`?** When are they decrypted — at build time or activation time?

5. **How would you add a second machine** (e.g., a second server) that also needs the same secret? What do you change in `secrets.nix`?
