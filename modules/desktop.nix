{
  config,
  pkgs,
  ...
}: {
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
    desktopManager.gnome.enable = true;
    videoDrivers = ["nvidia"];
    deviceSection = ''
      BusID "PCI:11:0:0"
    '';
    xkb = {
      layout = "us";
      variant = "";
      options = "altwin:swap_alt_win";
    };
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-console
    gnome-terminal
    cheese
    gnome-music
    epiphany
    geary
    totem
    gnome-maps
    gnome-contacts
    gnome-calendar
    gnome-logs
    yelp
    simple-scan
  ];

  environment.sessionVariables = {
    TERMINAL = "terminator";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  programs.bash.shellAliases = {
    "x-terminal-emulator" = "terminator";
  };
}
