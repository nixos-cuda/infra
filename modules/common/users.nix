{
  users = {
    mutableUsers = false;

    users = {
      root = {
        isSystemUser = true;
        hashedPassword = "$y$j9T$3Qa7kcRIilZH/xsek7HDj.$dIYHS1eIgPkJcIJsX1WsgeRC0NkT6XLNxx.u7MZ4Ti/";
      };

      nix = {
        isNormalUser = true;
        group = "nix";
      };
    };
    groups.nix = { };
  };
}
