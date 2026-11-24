{
  inputs,
  lib,
  gnused,
  writeScriptBin,
}:
let
  defs = inputs.self.hosts;
  prefixPriorities = {
    htz = "0";
    ttn = "1";
    oxi = "2";
    brv = "3";
  };
  sortedNames = lib.sortOn (
    name: "${prefixPriorities.${lib.substring 0 3 name}}${lib.substring 3 (-1) name}"
  ) (lib.attrNames defs);
  hosts = map (hostname: defs.${hostname} // { inherit hostname; }) sortedNames;
  columns = [
    {
      header = "Hostname";
      get = hostCfg: hostCfg.hostname;
    }
    {
      header = "Purpose";
      get = hostCfg: hostCfg.purpose;
    }
    {
      header = "IP";
      get =
        hostCfg:
        "`${hostCfg.hostname}.nixos-cuda.org`${lib.optionalString (hostCfg.ip != null) " - ${hostCfg.ip}"}";
    }
    {
      header = "system";
      get =
        let
          modulesPath = "${inputs.nixpkgs}/nixos/modules";
        in
        hostCfg:
        (lib.evalModules {
          modules = hostCfg.profiles ++ [
            { _module.check = false; }
            "${modulesPath}/misc/nixpkgs.nix"
          ];
          specialArgs = {
            inherit inputs modulesPath;
            isLinux = false;
            isDarwin = false;
          };
        }).config.nixpkgs.localSystem.system;
    }
    {
      header = "GPU";
      get = hostCfg: if hostCfg ? gpu then hostCfg.gpu.name else "-";
    }
    {
      header = "GPU architecture";
      get = hostCfg: if hostCfg ? gpu then hostCfg.gpu.arch else "-";
    }
  ];
  data = map (
    c:
    c
    // rec {
      data = map c.get hosts;
      width = lib.foldr lib.max (lib.stringLength c.header) (map lib.stringLength data);
    }
  ) columns;
  pad =
    width: str: lib.concatStrings ([ str ] ++ (lib.replicate (width - (lib.stringLength str)) " "));
  hostsmd = ''
    | ${lib.concatMapStringsSep " | " (c: pad c.width c.header) data} |
    |-${lib.concatMapStringsSep "-|-" (c: lib.strings.replicate c.width "-") data}-|
    ${lib.concatStringsSep "\n" (
      lib.genList (
        i: "| ${lib.concatMapStringsSep " | " (c: pad c.width (lib.elemAt c.data i)) data} |"
      ) (lib.length hosts)
    )}
  '';
in
writeScriptBin "update-readme.sed" ''
  #!${lib.getExe gnused} -nf
  # Print all lines
  p
  # When encounter the start line
  /^<!--begin hosts table-->$/ {
    # It will already be printed
    # Append contents of the generated doc file
    r ${lib.toFile "hosts.md" hostsmd}
    # Set a label for iteration
    :0
    # Until we find the end line
    /^<!--end hosts table-->$/! {
      # Advance to the next lien
      n
      # Jump to the label
      b0
    }
    # Print the end line
    p
  }
  # We consumed all lines between start and end lines
''
