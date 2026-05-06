{...}: {
  imports = [
    ./hardware-configuration.nix
    ./modules/boot.nix
    ./modules/audio.nix
    ./modules/users.nix
    ./modules/gaming.nix
    ./modules/sunshine.nix
    ./modules/nvidia.nix
    ./modules/desktop.nix
    ./modules/network.nix
    ./modules/filesystems.nix
    ./modules/librewolf.nix
    ./modules/packages.nix
    ./modules/container.nix
    ./modules/security.nix
    ./modules/ssh.nix
    ./modules/home.nix
    ./modules/music.nix
    ./modules/overlays.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.allowed-users = ["@wheel"];
  nix.settings.trusted-users = ["root"]; # NICHT alle wheel-User
  nix.settings.sandbox = true;

  networking.hostName = "nixos";
  time.timeZone = "Europe/Berlin";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "de_DE.UTF-8";
    LC_IDENTIFICATION = "de_DE.UTF-8";
    LC_MEASUREMENT = "de_DE.UTF-8";
    LC_MONETARY = "de_DE.UTF-8";
    LC_NAME = "de_DE.UTF-8";
    LC_NUMERIC = "de_DE.UTF-8";
    LC_PAPER = "de_DE.UTF-8";
    LC_TELEPHONE = "de_DE.UTF-8";
    LC_TIME = "de_DE.UTF-8";
  };

  services.printing.enable = true;

  system.stateVersion = "25.11";
}
