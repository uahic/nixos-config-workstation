{pkgs, ...}: {
  programs.steam = {
    enable = true;
    package = pkgs.steam;
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  environment.systemPackages = with pkgs; [
    lutris
    protonup-qt
    protontricks
    wineWow64Packages.staging
    winetricks
    nvtopPackages.nvidia
  ];
}
