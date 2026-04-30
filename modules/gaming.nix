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
    wineWowPackages.staging # Wine 32+64 bit, staging hat oft bessere Kompatibilität
    winetricks
    nvtopPackages.nvidia
  ];
}
