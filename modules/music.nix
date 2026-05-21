{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    #musescore
    muse-sounds-manager
  ];
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    alsa-lib
    libjack2
    libGL
    freetype
    fontconfig
    glib
    zlib
    stdenv.cc.cc.lib
    xorg.libX11
    xorg.libXext
    xorg.libXrandr
    xorg.libXcursor
    xorg.libXi
    xorg.libxcb
    xorg.libXrender
    xorg.libXfixes
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXtst
  ];
}
