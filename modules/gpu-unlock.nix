# modules/gpu-unlock.nix
#
# Declarative install of https://github.com/Zagitta/gpu-unlock, which
# patches Ampere (GA102/103/104/106) GSP firmware to double FP16/BF16
# FMA-into-FP32 issue rate on consumer cards (RTX 3090 among others).
#
# Replaces the manual `nix-shell ... --run 'make inputs && make firmware'`
# + `make -C kernel/gpu_unlock KDIR=...` steps with two Nix derivations,
# wired into boot.extraModulePackages / hardware.firmware so the module
# and its patched firmware are (re)built on every `nixos-rebuild`.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  kernel = config.boot.kernelPackages.kernel;

  # Matches the `NV` version pinned in gpu-unlock's Makefile. Bump this
  # (and re-check upstream's Makefile) if the project updates it.
  nvVersion = "610.43.03";

  # `make inputs` downloads ~340MB of NVIDIA/CachyOS artifacts and
  # verifies them against hashes pinned in gpu-unlock's own
  # firmware/artifacts-${nvVersion}.json, then `make firmware` patches
  # them into 5 firmware blobs. Both need network access, so this is
  # wrapped as one fixed-output derivation rather than reimplementing
  # the fetch+patch pipeline with fetchurl.
  gpu-unlock-firmware = pkgs.stdenv.mkDerivation {
    pname = "gpu-unlock-firmware";
    version = nvVersion;
    src = inputs.gpu-unlock;

    nativeBuildInputs = [pkgs.gnumake pkgs.python3 pkgs.zstd pkgs.cacert];

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = "sha256-hCRL7bghgOzvASR0aejR7+1kQ8jHBrKmCvNkKtk+ym0=";

    SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

    buildPhase = ''
      runHook preBuild
      export HOME=$TMPDIR
      make inputs
      make firmware
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm444 -t $out/lib/firmware/gpu-unlock/${nvVersion} \
        "$HOME"/.cache/gpu-unlock/assets/booter_load_ga102.bin \
        "$HOME"/.cache/gpu-unlock/assets/gsp_ga10x.bin \
        "$HOME"/.cache/gpu-unlock/assets/gsp_boot_ga102.bin \
        "$HOME"/.cache/gpu-unlock/assets/gsp_boot_desc_ga102.bin \
        "$HOME"/.cache/gpu-unlock/assets/v67-ga102-${nvVersion}.bin
      runHook postInstall
    '';
  };

  # Out-of-tree kernel module, built against the headers/toolchain of
  # the kernel this NixOS generation actually boots - the declarative
  # equivalent of the manual `nix develop .../kernel -c make ...` step.
  gpu-unlock-module = pkgs.stdenv.mkDerivation {
    pname = "gpu_unlock";
    version = "1.0.0";
    src = inputs.gpu-unlock;

    nativeBuildInputs = kernel.moduleBuildDependencies;

    buildPhase = ''
      runHook preBuild
      make -C kernel/gpu_unlock KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm444 kernel/gpu_unlock/gpu_unlock.ko \
        $out/lib/modules/${kernel.modDirVersion}/extra/gpu_unlock.ko
      runHook postInstall
    '';

    meta = {
      description = "Unlocks full FP16/BF16 FMA throughput on consumer Ampere NVIDIA GPUs";
      license = lib.licenses.gpl2Only;
      platforms = ["x86_64-linux"];
    };
  };
in {
  hardware.firmware = [gpu-unlock-firmware];

  boot.extraModulePackages = [gpu-unlock-module];
  boot.kernelModules = ["gpu_unlock"];

  # Upstream loads this before nvidia.ko binds via mkinitcpio/dracut/
  # initramfs-tools hooks on other distros. Mirroring that via initrd
  # here to give it the best chance of winning that race - untested on
  # this exact NixOS/nvidia setup, verify with `dmesg | grep gpu_unlock`
  # after rebuilding.
  boot.initrd.kernelModules = ["gpu_unlock"];

  boot.kernelParams = [
    # "all" unlocks every matching card. Swap for a comma-separated list
    # of PCI addresses (see `lspci -d 10de: -D`) to unlock only one of
    # the two 3090s, e.g. for an A/B benchmark.
    "gpu_unlock.targets=all"
  ];
}
