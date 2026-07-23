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
    stow # For dot files
    mupdf #
    gimp
    alejandra # Nix File formatting
    terminator
    evolution # Email
    obsidian # Markdown note editor
    pnpm # Node package manager for web dev
    mtr # MTR fur udp monitoring
    vscode-fhs # Nix compatible VSCode
    pre-commit # Git pre-commit
    gnomeExtensions.appindicator
    gnomeExtensions.dash-to-dock
    libreoffice
  ];

  environment.sessionVariables = {
    OBSIDIAN_USE_WAYLAND = "1";
  };
}
