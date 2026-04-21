{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./modules/sunshine.nix
    ./modules/nvidia.nix
    ./modules/desktop.nix
    ./modules/network.nix
    ./modules/filesystems.nix
    ./modules/librewolf.nix
    ./modules/packages.nix
    ./modules/home.nix
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

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

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelParams = [
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    "nvidia.NVreg_TemporaryFilePath=/var/tmp"
    "iomem=relaxed"
  ];
  boot.supportedFilesystems = ["nfs"];

  services.openssh.enable = true;
  services.printing.enable = true;

  security.rtkit.enable = true;
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.eumel = {
    isNormalUser = true;
    description = "eumel";
    extraGroups = ["networkmanager" "wheel"];
  };

  system.stateVersion = "25.11";
}
