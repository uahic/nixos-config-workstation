{
  config,
  pkgs,
  lib,
  ...
}: let
  # lib.makeOverridable ist noetig damit programs.firefox intern .override aufrufen kann.
  # Unsere Funktion nimmt die gleichen Override-Args wie pkgs.librewolf, wendet sie an,
  # und verpackt das Ergebnis dann in den systemd-run Wrapper.
  librewolf = lib.makeOverridable (args: let
    base = pkgs.librewolf.override args;
  in
    pkgs.symlinkJoin {
      name = "librewolf";
      paths = [base];
      nativeBuildInputs = [pkgs.makeWrapper];
      postBuild = ''
        rm $out/bin/librewolf
        makeWrapper ${pkgs.systemd}/bin/systemd-run $out/bin/librewolf \
          --add-flags "--user --scope -p MemoryMax=5G -p MemoryHigh=4G -- ${base}/bin/librewolf"

        find $out/share/applications -name "*.desktop" | while read f; do
          cp --remove-destination "$(readlink "$f")" "$f"
          substituteInPlace "$f" \
            --replace "${base}/bin/librewolf" "$out/bin/librewolf"
        done
      '';
    }) {};
in {
  programs.firefox = {
    enable = true;
    package = librewolf;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      Preferences = {
        # Memory management
        "browser.tabs.unloadOnLowMemory" = true;
        "browser.low_commit_space_threshold_mb" = 1024; # Tab-Unload unter 1 GB freiem RAM
        "browser.cache.memory.capacity" = 524288; # Memory-Cache max 512 MB (in KB)
        "dom.ipc.processCount" = 4; # Content-Prozesse begrenzen (Standard: 8)

        "cookiebanners.service.mode.privateBrowsing" = 2;
        "cookiebanners.service.mode" = 2;
        "privacy.donottrackheader.enabled" = true;
        "privacy.fingerprintingProtection" = true;
        "privacy.resistFingerprinting" = true;
        "privacy.trackingprotection.emailtracking.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.fingerprinting.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
      };
      ExtensionSettings = {
        "jid1-ZAdIEUB7XOzOJw@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/duckduckgo-for-firefox/latest.xpi";
          installation_mode = "force_installed";
        };
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };

  environment.etc."firefox/policies/policies.json".target = "librewolf/policies/policies.json";
}
