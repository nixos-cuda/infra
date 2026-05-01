# Cf.
# - https://copy.fail,
# - https://github.com/theori-io/copy-fail-CVE-2026-31431/issues/48,
# - https://discourse.nixos.org/t/is-nixos-affected-by-copy-fail/77317.
#
# Fix backported on: 6.18.22+, 6.19.12+ and 7.0+,
# per https://discourse.nixos.org/t/is-nixos-affected-by-copy-fail/77317/2.

{ lib, pkgs, ... }:
let
  # The list copied from https://discourse.nixos.org/t/is-nixos-affected-by-copy-fail/77317/4
  affectedModules = [
    "af_alg"
    "algif_hash"
    "algif_skcipher"
    "algif_rng"
    "algif_aead"
  ];
in
{
  boot.blacklistedKernelModules = affectedModules;
  systemd.services.rmmod-copy-fail = {
    wantedBy = [ "default.target" ];
    path = [ pkgs.gnugrep ];
    environment = {
      affectedModules = lib.concatStringsSep " " affectedModules;
    };
    script = ''
      isLoaded() {
          /run/current-system/sw/bin/lsmod | grep -q "^$1\b"
      }
      for m in $affectedModules ; do
          if isLoaded "$m" ; then
              /run/current-system/sw/bin/modprobe -r "$m"
          fi
      done
      ret=0
      for m in $affectedModules ; do
          if isLoaded "$m" ; then
              ret=1
              echo "$m hasn't been unloaded" >&2
          fi
      done
      exit $ret
    '';
  };
}
