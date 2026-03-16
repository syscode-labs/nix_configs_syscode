# SSH Configuration for Remote Deployments

## Setup

Add this to your `~/.ssh/config` on your main laptop:

```ssh
# NixOS Remote Machines
Host laptop
  HostName laptop.local  # or IP address
  User giovanni
  ForwardAgent yes
  ControlMaster auto
  ControlPath ~/.ssh/control-%r@%h:%p
  ControlPersist 10m

Host remote-machine
  HostName 192.168.1.100  # Replace with actual IP
  User giovanni
  ForwardAgent yes
  ControlMaster auto
  ControlPath ~/.ssh/control-%r@%h:%p
  ControlPersist 10m

# Add more hosts as needed
```

## SSH Agent Forwarding

SSH agent forwarding allows remote machines to use your local SSH keys without copying them.

### Enable on macOS/Linux:
```bash
# Add to ~/.bashrc or ~/.zshrc
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519  # or your key path
```

### macOS specific (~/.ssh/config):
```ssh
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

## Remote Build Configuration

For NixOS remote builds, ensure:

1. Your user has sudo rights on remote machines
2. SSH key authentication is set up
3. Remote machine has Nix installed with flakes enabled

## Testing

Test SSH connection:
```bash
ssh laptop 'echo "SSH works!"'
```

Test agent forwarding:
```bash
ssh -A laptop 'ssh-add -l'
```

This should show your local SSH keys available on the remote machine.
