{pkgs, ...}: {
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
    obsidian
    pnpm
    vscode-fhs
    pre-commit
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];

  environment.sessionVariables = {
    OBSIDIAN_USE_WAYLAND = "1";
  };
}
