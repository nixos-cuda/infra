{ inputs, ... }:
{
  imports = [ inputs.gradient.nixosModules.default ];

  # TODO: currently separate container for testing, later in a microvm
  containers.gradient = {
    autoStart = true;

    config = {
      imports = [ inputs.gradient.nixosModules.default ];

      system.stateVersion = "26.05";
    };
  };
}
