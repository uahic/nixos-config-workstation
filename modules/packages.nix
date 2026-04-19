{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    wget
    curl
    cifs-utils
    nfs-utils
    vim
    vimPlugins.vim-nix
    git
    alejandra
    terminator
    evolution
    nvtopPackages.nvidia
    vscode-fhs
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];
}
