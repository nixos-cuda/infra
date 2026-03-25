{
  lib,
  rustPlatform,
  clippy,
}:
rustPlatform.buildRustPackage {
  name = "helpers";

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

  meta.mainProgram = "helpers";
}
