# modules/tailscale.nix
{
  config,
  lib,
  pkgs,
  ...
}: {
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
  };

  # CLI auch systemweit verfügbar (services.tailscale installiert es bereits,
  # diese Zeile ist nur explizit zur Klarheit)
  environment.systemPackages = [pkgs.tailscale];
}
