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
  easyeffects (runs as a service with Framework 13 speaker presets)

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

1. `mkdir hosts/<name>`, write `default.nix` + `hardware.nix` (+ `disko.nix`)
2. Add `<name> = mkHost "<name>";` to `flake.nix`
3. Import only the modules that apply
4. `ssh-to-age` the new host key into `.sops.yaml`, then
   `sops updatekeys secrets/secrets.yaml`
