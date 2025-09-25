{
  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  nix = {
    settings = {
      experimental-features = "nix-command flakes";

      warn-dirty = false;
    };

    # Garbage collection
    gc = {
      automatic = true;
      dates = "05:00";
      options = "--delete-older-than 10d";
    };
  };
}
