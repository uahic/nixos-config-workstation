{
  config,
  pkgs,
  ...
}: {
  # configuration.nix
  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # "docker" Befehl zeigt auf podman
  };

  # Rootless Podman braucht das:
  security.unprivilegedUsernsClone = true;

  # Netzwerk-Tools für Container
  environment.systemPackages = with pkgs; [
    podman-compose
    podman-tui # optionales Terminal-UI
  ];
}
