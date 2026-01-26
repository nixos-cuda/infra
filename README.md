# NixOS-CUDA CI/CD

[NixOS-CUDA](https://hydra.nixos-cuda.org) CI/CD Infrastructure, including NixOS configurations for Hydra and the builders.
This is not an official NixOS project.

## Scope

The purpose of this system is to advance maintainability of hardware-accelerated (specifically CUDA) software in Nixpkgs.
Sustainable maintenance and development of Nixpkgs CUDA requires both a comprehensive test suite run on-schedule, for retroactive detection,
and a lighter on-push test-suite for early notification of contributors and the prevention of regressions from being merged.

We aim to detect and distinguish between:
- build failures;
- breakages of basic functionality, like the loading of shared libraries by downstream applications in their GPU branches;
- architecture-specific errors;
- errors in collective communication libraries;
- regressions in performance and closure sizes.

## Hosts

Accounts of currently available hardware and access.

| Hostname  | Purpose                                                               | IP                                        | GPU                   | GPU architecture  |
|-----------|-----------------------------------------------------------------------|-------------------------------------------|-----------------------|-------------------|
| ada       | GPU builder                                                           | `ada.nixos-cuda.org` - 144.76.101.55      | RTX 4000 ada (SFF)    | Ada Lovelace      |
| pascal    | GPU builder                                                           | `pascal.nixos-cuda.org` - 95.216.72.164   | GeForce GTX 1080      | Pascal            |
| hydra     | Hydra + binary cache                                                  | `hydra.nixos-cuda.org` - 37.27.129.22     | -                     | -                 |
| atlas     | CPU builder                                                           | `atlas.nixos-cuda.org` - 95.216.20.88     | -                     | -                 |
| oxide-1   | CPU builder (provided by [Oxide computers](https://oxide.computer))   | `oxide-1.nixos-cuda.org` - 45.154.216.118 | -                     | -                 |

## [Hydra](https://hydra.nixos-cuda.org) jobsets

- [`cuda-gpu-tests`](https://hydra.nixos-cuda.org/jobset/cuda/cuda-gpu-tests): runs the nixpkgs GPU tests on builders with `cuda` capability.
- [`cuda-packages`](https://hydra.nixos-cuda.org/jobset/cuda/cuda-packages): builds `nixpkgs`'s [`release-cuda.nix`](https://github.com/NixOS/nixpkgs/blob/master/pkgs/top-level/release-cuda.nix) jobset.

## [Binary cache](https://cache.nixos-cuda.org)

Hydra's binary cache is exposed for development purposes.
For a compliant way to consume CUDA with Nix refer to [NVIDIA](https://developer.nvidia.com/blog/developers-can-now-get-cuda-directly-from-their-favorite-third-party-platforms).
The substituter is currently backed by [harmonia](https://github.com/nix-community/harmonia).

```nix
{
  nix.settings.substituters = [
    "https://cache.nixos-cuda.org"
  ];

  nix.settings.trusted-public-keys = [
    "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
  ];
}
```

## ROADMAP

- [ ] Coverage
    - [ ] Remove hard-coded attribute lists: cf. "Collect `gpuCheck`s by following `recurseIntoAttrs`" in "MVE"; same for packages.
    - [ ] Data-Center Hardware and Multi-GPU set-ups
      - [ ] Probably requires ephemeral builders due to cost.
      - [ ] Currently no multi-GPU/collective communications test-suites available in Nixpkgs.
    - [ ] Jetson (tentatively, based on owned hardware and colocation)
- [ ] Efficiency:
    - [ ] `harmonia` → `snix-narbridge`;
    - [ ] virtiofsd flat stores → snix virtiofs; in particular, we should hope to eliminate the inefficient Nix substitution;
    - [ ] Ephemeral Builders:
        - [ ] Make NixOS work on Azure (under pain limits).
        - [ ] Basic functionality: on-demand deployment and automatic deallocation of remote builders; the hooking up the builders to Hydra.
        - [ ] IO costs: synchronizing the closures is likely to be the bottleneck. Cf. the snix virtio story.
- [ ] Isolation and Access Control:
    - [ ] [Serge] Move remote builders, Hydra, and web services to microvms with isolated stores.
    - [ ] Prevent unaudited SSH access to hypervisors and to Hydra (currently Gaetan and Serge in authorized keys).
    - [ ] Pull-based Deployment.
- [x] Mimimal Viable Example:
    - [x] [third parties via Jonas] Initial funding for GPU hardware.
    - [x] [Jonas] GitHub organization, domain names, web page.
    - [x] [Gaetan] Set up NixOS and Hydra.
    - [x] [Gaetan] ZFS Nix store on `ada`, `pascal`.
    - [x] [Gaetan] Set up `sops-nix` for managing the secrets.
    - [x] [Gaetan] Hydra.
        - [x] [Gaetan] Back up the Hydra configuration (DB?, jobsets?).
        - [x] [Gaetan] Move Hydra to `ada` (more storage available).
        - [x] [Serge] Figure out how Hydra inputs work.
        - [x] Open PR for cuda-gpu-tests jobset (currently the input points at Gaetan's branch)
            -> https://github.com/NixOS/nixpkgs/pull/454251
        - [x] Collect `gpuCheck`s by following `recurseIntoAttrs` and `passthru.tests` (currently using a hard-coded list).
            -> https://github.com/nixos-cuda/hydra-jobsets/pull/2
        - [x] Declarative jobsets (currently configured via web UI).
            -> https://github.com/nixos-cuda/hydra-jobsets/pull/4
    - [x] [Gaetan] Expose binary cache
