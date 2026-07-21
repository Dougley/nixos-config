# nixos-config

Flake-based NixOS with home-manager as a NixOS module.

| Host | Machine |
|---|---|
| kyurem | Framework 13 (Ryzen AI 9 HX 370) |

## Layout

```
flake.nix           inputs + mkHost helper; one line per host
hosts/              host-specific: boot chain, users, snapshots, disko layout
modules/base.nix    nix settings, nh, nix-ld, zram, locale, ssh, core CLI
modules/desktop.nix Plasma 6, pipewire, Steam, fonts, declarative flatpaks
modules/laptop.nix  fwupd, fprintd, lid/suspend behavior, bluetooth, bolt
modules/containers.nix  podman (docker-compatible) + distrobox
home/remco/         home-manager: zsh/antidote, starship, fzf, git,
                    plasma-manager config, easyeffects presets
secrets/            sops-nix encrypted secrets (recipients in .sops.yaml)
```

## What's notable

- **Disk**: declarative via disko: 1G ESP + LUKS2 → btrfs flat subvolumes
  (`@ @home @nix @snapshots @swap`), zstd compression, 68G swapfile for
  hibernation ([hosts/kyurem/disko.nix](hosts/kyurem/disko.nix))
- **Boot**: lanzaboote secure boot (self-enrolled keys), systemd initrd,
  TPM2 auto-unlock for LUKS, Plymouth quiet boot, boot counting
- **Snapshots**: snapper timelines on `/` and `/home`, monthly btrfs scrub
- **Secrets**: sops-nix; encrypted to an editing age key and the host SSH
  key, decrypted at activation. Edit with `sops secrets/secrets.yaml`
- **Apps**: GUI apps are mostly flatpaks, converged declaratively by
  nix-flatpak (`uninstallUnmanaged = true`; the list in `desktop.nix` *is*
  the installed set). Native exceptions where sandboxing breaks things:
  Firefox and 1Password (browser integration), Steam (drivers/gamescope),
  easyeffects (runs as a service with the Cab's_20Fav output preset)

## Install (fresh disk)

Boot the minimal NixOS ISO with secure boot **disabled** (or in setup
mode), get online, then:

```sh
# 1. Get the config
nix-shell -p git
git clone https://github.com/Dougley/nixos-config && cd nixos-config

# 2. Check that the disk node matches disko.nix (/dev/nvme0n1)
lsblk

# 3. Partition, format, and mount (this erases the disk and asks for the LUKS passphrase)
sudo nix --experimental-features "nix-command flakes" run \
  github:nix-community/disko -- --mode disko ./hosts/kyurem/disko.nix

# 4. Create Secure Boot keys before installation; Lanzaboote signs the
#    bootloader during nixos-install
sudo nix-shell -p sbctl --run "sbctl create-keys"
sudo mkdir -p /mnt/var/lib
sudo cp -r /var/lib/sbctl /mnt/var/lib/

# 5. Compare with the generated hardware configuration and merge any extra entries
sudo nixos-generate-config --no-filesystems --root /mnt --show-hardware-config

# 6. Install NixOS
sudo nixos-install --flake .#kyurem
```

Everything gets signed with your keys at install time; enrollment into
firmware happens post-install.

## Post-install, in order

```sh
# 1. Confirm that the boot chain is signed
sudo sbctl verify

# 2. In firmware setup, clear the Secure Boot keys. Boot back into NixOS,
#    then enroll the new keys:
sudo sbctl enroll-keys --microsoft   # Keeps vendor option ROMs bootable.
#    Restart, enable Secure Boot in firmware, then confirm:
bootctl status   # Shows "Secure Boot: enabled".

# 3. Enroll TPM2 for LUKS auto-unlock; keep the passphrase handy too
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7 /dev/nvme0n1p2

# 4. Check the hibernation resume offset. resume_offset=533760 matches this
#    swapfile; recalculate it after reinstalling and update the config if needed:
sudo btrfs inspect-internal map-swapfile -r /swap/swapfile

# 5. A few finishing touches
passwd                      # Set the account password.
sudo tailscale up
fprintd-enroll              # Enables fingerprints for sudo and the lock screen.
```

## Daily driving

```sh
rebuild     # Runs nh os switch with a diff.
update      # Updates the flake inputs.
agents-up   # Updates llm-agents and switches to the result.
```

- Rollback from the boot menu, or `sudo nixos-rebuild switch --rollback`
- Snapshots: `snapper list`, or Btrfs Assistant for a GUI
- Generations: nh's clean timer keeps 5 / 14 days; no manual `nix-collect-garbage`
- Run anything from nixpkgs once without installing: `, foo` (comma +
  prebuilt nix-index database)
- `nix fmt` formats the tree (treefmt wrapping nixfmt)
- Imperative leftovers (antidote clones, tldr cache, firmware): `topgrade`

## Secrets

```sh
sops secrets/secrets.yaml    # Edit with the age key in ~/.config/sops/age.
```

Recipients live in [.sops.yaml](.sops.yaml): your editing key plus each
host's SSH key (`ssh-to-age`). sops-nix decrypts at activation using the
host key; no key material in the store.

## Adding a host

Each host is a directory under `hosts/` plus one line in `flake.nix`.
Use [hosts/kyurem/](hosts/kyurem/) as the reference; it carries the full
laptop setup (secure boot, TPM2 unlock, hibernation, snapper), most of
which a new host can skip.

### 1. Create `hosts/<name>/`

Three files:

- `default.nix` — the entry point: flake module imports, hostname,
  users, home-manager wiring, host-specific services
- `hardware.nix` — from `nixos-generate-config --no-filesystems
  --show-hardware-config`: kernel modules, microcode, `nixpkgs.hostPlatform`.
  Leave out `fileSystems` entries when disko provides them
- `disko.nix` — optional but recommended: the declarative disk layout.
  Without it, keep the generated `fileSystems` in `hardware.nix` instead

A minimal `default.nix`:

```nix
{ inputs, pkgs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    # Check github:NixOS/nixos-hardware for a profile matching the machine.

    ./hardware.nix
    ./disko.nix

    ../../modules/base.nix
  ];

  networking.hostName = "<name>";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.remco = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
    initialPassword = "changeme";
  };
  programs.zsh.enable = true;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.remco = import ../../home/remco;
  };

  sops.defaultSopsFile = ../../secrets/secrets.yaml;

  # The NixOS release this host was first installed with; never bump it.
  system.stateVersion = "25.11";
}
```

Note that `home/remco/` assumes a desktop (plasma-manager, easyeffects,
GUI apps); a headless host wants a slimmed-down home config or none.

### 2. Register it in `flake.nix`

```nix
nixosConfigurations = {
  kyurem = mkHost "kyurem";
  <name> = mkHost "<name>";
};
```

`mkHost` hardcodes `x86_64-linux`; an aarch64 host needs the helper
extended with a system argument.

### 3. Pick modules

Import only what applies from `modules/`:

| Module | Import when |
|---|---|
| `base.nix` | always — nix settings, ssh, zram, core CLI |
| `desktop.nix` | the machine has a screen — Plasma 6, pipewire, flatpaks |
| `laptop.nix` | it's a laptop — fwupd, fprintd, power/lid handling |
| `containers.nix` | you want podman + distrobox |

Everything intentionally *not* in a shared module lives in the host's
`default.nix` — secure boot, snapshots, tailscale, 1Password — so copy
over the blocks from `hosts/kyurem/default.nix` that apply.

### 4. Wire up secrets

sops-nix decrypts with the host's SSH key, which only exists once the
host is installed (or you pre-generate one):

```sh
# On the new host (or against a pre-generated key):
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
```

Add the printed `age1...` key as a new anchor in [.sops.yaml](.sops.yaml)
and to the `creation_rules` key group, then re-encrypt:

```sh
sops updatekeys secrets/secrets.yaml
```

Until this is done, activation on the new host can't decrypt secrets —
on a fresh install, expect to install first, then rekey and rebuild.

### 5. Build and install

```sh
# Evaluation + build check from any machine, no switching:
nix build .#nixosConfigurations.<name>.config.system.build.toplevel

# Fresh machine: follow "Install (fresh disk)" above with .#<name>,
# skipping the sbctl steps unless the host uses lanzaboote.
```
