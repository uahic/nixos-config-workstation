# modules/tailscale.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  services.tailscale = {
    enable = true;
    openFirewall = false; # Fallback ueber DERP-Relay reicht fuer Client-Nutzung
    useRoutingFeatures = "client";
  };

  # CLI auch systemweit verfügbar (services.tailscale installiert es bereits,
  # diese Zeile ist nur explizit zur Klarheit)
  environment.systemPackages = [pkgs.tailscale];
}
