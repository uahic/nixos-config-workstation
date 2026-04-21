{
  config,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget
    curl
    cifs-utils
    nfs-utils
    vim
    vimPlugins.vim-nix
    git
    htop
    iotop
    stow
    alejandra
    terminator
    evolution
    nvtopPackages.nvidia
    vscode-fhs
    #    podman
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];

  #programs.firefox.enable = false;
  programs.steam = {
    enable = true;
    package = pkgs.steam;
  };
}
