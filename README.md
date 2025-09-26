# Nix-community CUDA-enabled builders

This repository hosts the NixOS configurations for the nix-community CUDA-enabled builders.

## Hosts

| Hostname  | IP            | GPU                   | GPU architecture  |
|-----------|---------------|-----------------------|-------------------|
| ada       | 144.76.101.55 | RTX 4000 ada (SFF)    | Ada Lovelace      |
| pascal    | 95.216.72.164 | GeForce GTX 1080      | Pascal            |

## TODO

- [ ] Repair `ada` by reinstalling NixOS with the new ZFS nix store
- [ ] Apply the same process to `pascal`
- [x] Set up `sops-nix` for managing the secrets
- [ ] Hydra
    - [ ] Back up the Hydra configuration (DB?, jobsets?)
    - [ ] Find a better solution for the cuda-gpu-tests jobset (rather than using my fork as input)
    - [ ] Use `ada` for hosting the hydra instance (more storage available)
