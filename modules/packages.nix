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
    obsidian
    lutris # Proton UI
    protonup-qt # zum einfachen Installieren von Proton-GE
    protontricks
    wineWowPackages.staging # Wine 32+64 bit, staging hat oft bessere Kompatibilität
    winetricks
    nvtopPackages.nvidia
    pnpm
    vscode-fhs
    #    podman
    pre-commit
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
  ];

  #programs.firefox.enable = false;
  programs.steam = {
    enable = true;
    package = pkgs.steam;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  programs.zsh.enable = true;

  environment.sessionVariables = {
    OBSIDIAN_USE_WAYLAND = "1";
  };
}
