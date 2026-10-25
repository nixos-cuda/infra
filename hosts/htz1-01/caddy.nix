{ pkgs, ... }:
{
  services.caddy.enable = true;
  services.caddy.package = pkgs.caddy.withPlugins {
    plugins = [
      # Seriously, rate-limiting requires a third party plug-in?
      "github.com/mholt/caddy-ratelimit@v0.1.0"
    ];
    hash = "sha256-nYE5/88oJ9Od6ohlzfr3uybPlNnrqnPccmIqyn1Kz7E=";
  };
}
