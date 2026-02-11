{
  lib,
  rustPlatform,
  clippy,
}:
rustPlatform.buildRustPackage {
  name = "hydra-channel-update-script";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.toml
      ./Cargo.lock
      ./src
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  nativeCheckInputs = [ clippy ];
  preCheck = ''
    echo "Running clippy..."
    cargo clippy -- -Dwarnings
  '';

  meta.mainProgram = "hydra-channel-update-script";
}
