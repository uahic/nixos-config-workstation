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
    libx11
    libxext
    libxrandr
    libxcursor
    libxi
    libxcb
    libxrender
    libxfixes
    libxcomposite
    libxdamage
    libxtst
  ];
}
