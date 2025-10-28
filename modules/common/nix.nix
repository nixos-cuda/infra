{
  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  nix = {
    settings = {
      experimental-features = "nix-command flakes";

      warn-dirty = false;

      trusted-users = [ "nix" ];

      extra-substituters = [
        "https://cache.flox.dev"
        "https://nix-community.cachix.org"
      ];
      extra-trusted-public-keys = [
        "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    # Garbage collection
    gc = {
      automatic = true;
      dates = "05:00";
      options = "--delete-older-than 30d";
    };
  };
}
