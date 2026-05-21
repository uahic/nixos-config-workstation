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
    tree
    htop
    iotop
    stow
    mupdf
    gimp
    alejandra
    terminator
    evolution
    obsidian
    pnpm
    mtr # MTR fur udp monitoring
    vscode-fhs
    pre-commit
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    libreoffice
  ];

  environment.sessionVariables = {
    OBSIDIAN_USE_WAYLAND = "1";
  };

  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
    host = "0.0.0.0";
    port = 11434;
    environmentVariables = {
      CUDA_DEVICE_ORDER = "PCI_BUS_ID";
      CUDA_VISIBLE_DEVICES = "1,0";
    };
  };
}
