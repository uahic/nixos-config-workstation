{unstable}: let
  qtRuntimeLibs = with unstable; [
    libxkbcommon
    fontconfig
    freetype
    dbus
    glib
    libGL
    zstd
    zlib
    xorg.libX11
    xorg.libXext
    xorg.libXrender
    xorg.libXi
    xorg.libXrandr
    xorg.libXcursor
    xorg.libXfixes
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXtst
    xorg.libxcb
    xorg.xcbutil
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
    xorg.xcbutilcursor
  ];
in {
  buildInputs = qtRuntimeLibs;

  shellHook = ''
    export LD_LIBRARY_PATH="${unstable.lib.makeLibraryPath qtRuntimeLibs}:$LD_LIBRARY_PATH"
    export QT_API=pyqt6
    export MPLBACKEND=QtAgg
    export QT_QPA_PLATFORM="wayland;xcb"

    if [ -d "$PWD/.venv/lib/python3.12/site-packages/PyQt6/Qt6/plugins" ]; then
      export QT_PLUGIN_PATH="$PWD/.venv/lib/python3.12/site-packages/PyQt6/Qt6/plugins"
    fi
  '';
}
