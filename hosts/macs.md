# Dealing with macs

## Bootstrapping

1. Create a password for the admin user in CUDA team collection in Vaultwarden
   at https://vault.nixos.org/#/vault?collectionId=e69da6a5-378f-4df4-99e1-5d23d240a16f
2. During initial setup process, create user `admin` with that password.
3. In Settings -> General -> Sharing, enable "Screen Sharing" and "Remote Login".
4. Get server SSH key via `ssh-keyscan IP`, add it to your known hosts.
5. Convert it to age key with `ssh-to-age`, add to `.sops.yaml` for `secrets-queue-runner.yaml`.
6. Run `sops updatekeys secrets-queue-runner.yaml`.
7. SSH onto new machine.
8. Fetch and unpack Nix installer tarball from the latest build of
   https://hydra.nixos.org/job/nix/maintenance-2.34/binaryTarball.aarch64-darwin
   (make sure Nix version matches the on in the current channel).
9. Run `./install --yes --no-channel-add --daemon`.
10. Run `echo 'PATH=$PATH:/nix/var/nix/profiles/default/bin' >> ~/.zshrc` to make
    sure Nix binaries are in PATH when connecting over SSH.
11. Deploy nix-darwin system with `deploy` command.
12. Cleanup root profile on the machine with `sudo nix profile remove nix nix-manual nss-cacert`.

## Upgrading

We need to keep an eye out for macOS upgrades.
* To check for updates, run `softwareupdate --list`, it will query for new software.
* To install updates, log in as `admin` account (not your user) and run:
  
  ```
  sudo softwareupdate --agree-to-license --no-scan --install --restart "UPDATE_LABEL"
  ```

  Replace `UPDATE_ID_STRING` with the label of the update in the list, for example, `macOS 27.2.1-26B131`.

  It will ask for a password, it must be the password of the admin account.
