# Vendored Hydra (Rust rewrite)

Nixpkgs packages and NixOS modules taken verbatim from
[NixOS/nixpkgs#563797](https://github.com/NixOS/nixpkgs/pull/563797)
("hydra: 0-unstable-2026-03-16 -> 0-unstable-2026-09-09"), which updates Hydra
to the Rust rewrite of the queue runner, evaluator and WebSocket log server.

Vendored from the `update/hydra` branch (Hydra `0-unstable-2026-09-09`,
`NixOS/hydra` rev `1d1d8b1c6fdc08444a514f383b291228f19d72d8`). The packages are
as published at PR head `7fb38b1b27212eb059138a1d2549d4fd50acdb6e`;
`nixos-modules/hydra/default.nix` additionally carries the
`queue_runner_endpoint` fix below, which still has to be folded into the PR.
Re-copy it once the PR is updated.

## Layout

| Path | Upstream path |
| --- | --- |
| `pkgs/hydra/package.nix` | `pkgs/by-name/hy/hydra/package.nix` |
| `pkgs/hydra/nix-perl.nix` | `pkgs/by-name/hy/hydra/nix-perl.nix` |
| `pkgs/hydra-builder/package.nix` | `pkgs/by-name/hy/hydra-builder/package.nix` |
| `pkgs/hydra-evaluator/package.nix` | `pkgs/by-name/hy/hydra-evaluator/package.nix` |
| `pkgs/hydra-queue-runner/package.nix` | `pkgs/by-name/hy/hydra-queue-runner/package.nix` |
| `pkgs/hydra-ws/package.nix` | `pkgs/by-name/hy/hydra-ws/package.nix` |
| `nixos-modules/hydra/default.nix` | `nixos/modules/services/continuous-integration/hydra/default.nix` |
| `nixos-modules/hydra/builder.nix` | `nixos/modules/services/continuous-integration/hydra/builder.nix` |

Those files are unmodified copies, so that re-syncing with the PR is a plain
`cp`. Everything that glues them into this repo lives in `overlay.nix` and
`nixos-modules/default.nix`.

## Our patches

`patches/` holds fixes that are *not* in the PR yet; `overlay.nix` applies them
with `overrideAttrs`, so the vendored `pkgs/` files stay verbatim. None of them
touch `Cargo.lock`, so the packages' `cargoHash` stays valid.

- `0001-hydra-builder-make-drv-available-to-pre-build-hook.patch` --
  `hydra-builder` only imports the closure of the *resolved* derivation's
  inputs, so the unresolved drv path Nix hands to `pre-build-hook` is not a
  valid store path on the agent. `nix-required-mounts` reads that path with
  `nix derivation show` to decide which devices to bind into the sandbox, so
  without this our CUDA steps build with no GPU. This is the `hydra-builder`
  counterpart of the `copyClosureTo` patch the C++ queue runner needed, which
  used to live in `hosts/hydra/hydra/`.
  Cf. [NixOS/nix#9272](https://github.com/NixOS/nix/issues/9272).

- `0002-queue-runner-skip-unparseable-drvpath.patch` --
  `get_not_finished_builds` parsed every row's `drvPath` and collected the
  batch into one `Result`, so a single unparseable row failed the whole query:
  the queue monitor read *no* builds and nothing was scheduled at all, with
  only an ERROR line per retry to say why. We hit this right after the
  migration, from 33 pre-migration builds whose `drvPath` was stored without
  the `/nix/store/` prefix (the Perl and C++ code treat the column as an opaque
  string, so they never minded). Those rows have since been normalised with
  `UPDATE builds SET drvpath = '/nix/store/' || drvpath WHERE drvpath NOT LIKE
  '/nix/store/%'`, but the fragility is worth removing.

Both patches are against `NixOS/hydra`, not nixpkgs, so they do not belong in
the nixpkgs PR -- they need their own upstream PRs.

## Fixed in the module, not yet in the PR

The module did not write `queue_runner_endpoint` to `hydra.conf`, which the web
app needs for `/machines` and `/queue-runner-status`, and without which
`hydra-send-stats` exits with an error. It now emits
`queue_runner_endpoint = http://<queueRunner.rest.address>:<port>` alongside
`base_uri` and friends, with a `nixos/tests/hydra` assertion that `/machines`
is non-empty.

`pkgs/*/package.nix` still carry `passthru.tests = { inherit (nixosTests) hydra; }`.
The NixOS test is not vendored, so `nixosTests.hydra` is the one from our
nixpkgs channel and will not work against these packages. Nothing evaluates it
here; it is kept only to avoid diverging from the PR.

## Dropping this

Once the PR is merged and our `nixpkgs` input contains it:

1. check whether `patches/` is still needed, and upstream whatever is,
2. delete this directory,
3. drop the `vendor/hydra/nixos-modules` import from `hosts/hydra/hydra` and
   from `modules/common/hydra-builder.nix`.

No option or package name changes are expected, since the vendored modules
are the upstream ones.
