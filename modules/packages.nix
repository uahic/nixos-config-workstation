{
  pkgs,
  inputs,
  ...
}: let
  vscodePkgs = import inputs.nixpkgs-vscode {
    inherit (pkgs) system;
    config.allowUnfree = true; # eigener pkg-Satz -> eigenes Unfree notwendig
  };
in {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vscodePkgs.vscode-fhs # Nix compatible VSCode
    wget
    curl
    cifs-utils
    nfs-utils
    vim
    vimPlugins.vim-nix
    git
    tree
    htop
    iotop
    iptables
    stow # For dot files
    mupdf #
    gimp
    alejandra # Nix File formatting
    terminator
    evolution # Email
    obsidian # Markdown note editor
    pnpm # Node package manager for web dev
    mtr # MTR fur udp monitoring
    pre-commit # Git pre-commit
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    libreoffice
    mullvad-browser
    mullvad-vpn
  ];

  services.mullvad-vpn.enable = true;

  environment.sessionVariables = {
    OBSIDIAN_USE_WAYLAND = "1";
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
  };
}
