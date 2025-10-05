{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      warn-dirty = false;

      trusted-users = [ "nix" ];

      extra-substituters = [
        "https://nix-cache.ynh.ovh"
      ];
      extra-trusted-public-keys = [
        "nix-cache.ynh.ovh:9qrjMrCm2hFYIuEgexkBxJTG0/6kT2jqd8muFtUezbk="
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
