{...}: {
  perSystem = {pkgs, ...}: let
    texlive-env = pkgs.texlive.combine {
      inherit
        (pkgs.texlive)
        scheme-full
        latexmk
        chktex
        biber
        graphics
        tcolorbox
        amsmath
        luatex
        koma-script
        fontspec
        microtype
        fontsize
        anyfontsize
        fontawesome5
        ;
    };
    perlWithDeps = pkgs.perl.withPackages (p: [
      p.YAMLTiny
      p.FileHomeDir
      p.UnicodeLineBreak
    ]);
    # Use kpsewhich at runtime to locate latexindent.pl — avoids hardcoding
    # any internal texlive store path that changes between rebuilds.
    latexindent-wrapped = pkgs.writeShellScriptBin "latexindent" ''
      script=$(${texlive-env}/bin/kpsewhich -format=texmfscripts latexindent.pl)
      exec ${perlWithDeps}/bin/perl "$script" "$@"
    '';
  in {
    packages.latexindent = latexindent-wrapped;

    devShells.latex = pkgs.mkShell {
      packages = [
        texlive-env
        pkgs.tex-fmt
        latexindent-wrapped
      ];
    };
  };
}
