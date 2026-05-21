# modules/overlays.nix
{inputs, ...}: {
  nixpkgs.overlays = [
    (final: prev: {
      openldap = prev.openldap.overrideAttrs (_: {doCheck = false;});
    })
    #(final: prev: {
    #  musescore = inputs.nixpkgs-stable.legacyPackages.${prev.system}.musescore;
    #})
  ];
}
