{
  users = {
    mutableUsers = false;

    users = {
      nix = {
        isNormalUser = true;
        group = "nix";
      };
    };
    groups.nix = { };
  };
}
