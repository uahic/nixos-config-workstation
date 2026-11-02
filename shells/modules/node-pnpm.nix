{
  pkgs,
  javaVersion ? pkgs.jdk21,
}: {
  buildInputs = with pkgs; [
    nodejs_22
    pnpm
    javaVersion
  ];

  shellHook = ''
    echo "Entered $(basename $PWD) environment"
  '';
}
