# Hydra (Rust rewrite) from unstable

Hydra's Rust rewrite of the queue runner, evaluator and WebSocket log server
landed in nixpkgs via
[NixOS/nixpkgs#563797](https://github.com/NixOS/nixpkgs/pull/563797) (merged
2026-10-04, `1becb0e39d8e9c0fb8168fa575a084128d59584e`), which is after the
26.05 branch-off. The rest of the fleet runs stable, so the Hydra packages and
their NixOS modules come from the separate `nixpkgs-hydra` input
(`nixos-unstable-small`) instead.

These files used to be verbatim copies of the PR's packages and modules. Now
that it is merged, only the glue and our own patches live here:

| Path | What it does |
| --- | --- |
| `overlay.nix` | Takes `hydra`, `hydra-{builder,evaluator,queue-runner,ws}` from `nixpkgs-hydra` and applies `patches/` |
| `nixos-modules/default.nix` | Imports `services.hydra{,-builder}` from `nixpkgs-hydra`, disabling stable's Hydra module |
| `patches/` | Fixes not upstream yet |

The packages are taken from the other package set as-is, so they are built
against the nixpkgs their modules were written for; the modules themselves are
evaluated by *our* `lib` and alongside *our* postgresql/systemd modules, which
works today but is the thing most likely to break on an input bump.

## Our patches

`overlay.nix` applies these with `overrideAttrs`. Neither touches
`Cargo.lock`, so the packages' `cargoHash` stays valid.

- `0001-hydra-builder-make-drv-available-to-pre-build-hook.patch` --
  `hydra-builder` only imports the closure of the *resolved* derivation's
  inputs, so the unresolved drv path Nix hands to `pre-build-hook` is not a
  valid store path on the agent. `nix-required-mounts` reads that path with
  `nix derivation show` to decide which devices to bind into the sandbox, so
  without this our CUDA steps build with no GPU. This is the `hydra-builder`
  counterpart of the `copyClosureTo` patch the C++ queue runner needed.
  Cf. [NixOS/nix#9272](https://github.com/NixOS/nix/issues/9272) and
  [NixOS/hydra#1565](https://github.com/NixOS/hydra/pull/1565); needs
  reshaping as an opt-in setting before it is upstreamable, since as written
  it makes every build fetch the whole derivation graph.

- `0002-queue-runner-skip-unparseable-drvpath.patch` --
  `get_not_finished_builds` parsed every row's `drvPath` and collected the
  batch into one `Result`, so a single unparseable row failed the whole query:
  the queue monitor read *no* builds and nothing was scheduled at all, with
  only an ERROR line per retry to say why. We hit this right after the
  migration, from 33 pre-migration builds whose `drvPath` was stored without
  the `/nix/store/` prefix (the Perl and C++ code treat the column as an opaque
  string, so they never minded). Those rows were normalised with
  `UPDATE builds SET drvpath = '/nix/store/' || drvpath WHERE drvpath NOT LIKE
  '/nix/store/%'`, but the fragility is worth removing.

Both patch `NixOS/hydra`, not nixpkgs, so they need their own upstream PRs.

**They are pinned to a Hydra `src` rev by nothing but luck.** `nixpkgs-hydra`
currently builds Hydra `0-unstable-2026-09-09`
(`1d1d8b1c6fdc08444a514f383b291228f19d72d8`), which is what they were written
against. When upstream bumps Hydra, `patch -p1` may stop applying -- at build
time, on whoever runs `nix flake update`. Re-check them on every bump of this
input.

## Dropping this

Once our stable nixpkgs carries the rewrite (26.11), and the patches are either
upstreamed or no longer needed:

1. drop the `nixpkgs-hydra` input from `flake.nix`,
2. delete this directory,
3. drop the `vendor/hydra/nixos-modules` import from `hosts/hydra/hydra` and
   from `modules/common/hydra-builder.nix`.
