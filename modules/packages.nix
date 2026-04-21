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
    alejandra
    terminator
    evolution
    nvtopPackages.nvidia
    vscode-fhs
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];

  programs.firefox.enable = true;
  programs.steam = {
    enable = true;
    package = pkgs.steam;
  };
}
