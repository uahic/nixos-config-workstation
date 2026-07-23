{pkgs, ...}: {
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
    ./modules/home.nix
    ./modules/music.nix
    ./modules/ollama.nix
    #./modules/openclaw.nix
    ./modules/tailscale.nix
    ./modules/waydroid.nix
    ./overlays.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];
  nix.settings.allowed-users = ["@wheel"];
  nix.settings.trusted-users = ["root"]; # NICHT alle wheel-User
  nix.settings.sandbox = true;

  # Compute limitieren fur nix-builds
  nix.settings.max-jobs = 3; # max. 3 parallele Jobs
  nix.settings.cores = 2; # je Job 2 Kerne → max. 6 Kerne (Hälfte von 12)

  systemd.slices."nix-builds".sliceConfig = {
    CPUAccounting = true;
    CPUQuota = "200%";
    MemoryMax = "10G";
    MemoryHigh = "7G";
  };
  systemd.services.nix-daemon.serviceConfig = {
    Slice = "nix-builds.slice";
    CPUQuota = "200%";
    MemoryMax = "10G";
    MemoryHigh = "7G";
  };

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
