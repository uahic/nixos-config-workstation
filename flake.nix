# ~/nixos-config/flake.nix
{
  description = "eumel's NixOS Konfiguration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-vscode.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-openclaw.url = "github:openclaw/nix-openclaw";

    gpu-unlock = {
      url = "github:Zagitta/gpu-unlock";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    ...
  }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs;}; # ← damit die Module `inputs` sehen
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager # ← ersetzt <home-manager/nixos>
      ];
    };

    flakeModules = {
      latex = ./shells/modules/latex.nix;
    };

    lib.mkCudaPythonShell = import ./shells/modules/cuda-python.nix;
    lib.mkQtDevShell = import ./shells/modules/qt-dev.nix;
    lib.mkNodePnpmShell = import ./shells/modules/node-pnpm.nix;
  };
}
