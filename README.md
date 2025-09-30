# Nixos-cuda infrastructure

This repository hosts the NixOS configurations for the [nixos-cuda](https://github.com/nixos-cuda) various builders.

## Hosts

| Hostname  | IP                                    | GPU                   | GPU architecture  |
|-----------|---------------------------------------|-----------------------|-------------------|
| ada       | `ada.nixos-cuda.org` - 144.76.101.55  | RTX 4000 ada (SFF)    | Ada Lovelace      |
| pascal    | `ada.nixos-cuda.org` - 95.216.72.164  | GeForce GTX 1080      | Pascal            |

## Services

### [Hydra](https://hydra.nixos-cuda.org)

Two jobsets:
- `cuda-gpu-tests`: Runs the nixpkgs tests that run on a GPU.
- `cuda-gpu-tests`: Builds `nixpkgs`'s [`release-cuda.nix`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/release-cuda.nix) jobset.

Runs on `ada`.

### [Binary cache](https://cache.nixos-cuda.org)

Backed up by [harmonia](https://github.com/nix-community/harmonia).

Runs on `ada`.

## TODO

- [x] Repair `ada` by reinstalling NixOS with the new ZFS nix store
- [x] Apply the same process to `pascal`
- [x] Set up `sops-nix` for managing the secrets
- [ ] Hydra
    - [x] Back up the Hydra configuration (DB?, jobsets?)
    - [x] Use `ada` for hosting the hydra instance (more storage available)
    - [ ] Find a better solution for the cuda-gpu-tests jobset (rather than using my fork as input)
- [x] Add a public cache for people (who?) to use (harmonia?)
