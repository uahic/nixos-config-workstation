{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: {
  microvm.vms.openclaw = {
    specialArgs = {inherit inputs;};

    config = {
      config,
      pkgs,
      lib,
      ...
    }: {
      imports = [
        inputs.microvm.nixosModules.microvm
        inputs.home-manager.nixosModules.home-manager
      ];

      networking.hostName = "openclaw";
      system.stateVersion = "24.11";

      # ─── microvm-Settings ─────────────────────────────────────
      microvm = {
        hypervisor = "qemu";
        vcpu = 2;
        mem = 4096;

        interfaces = [
          {
            type = "tap";
            id = "vm-openclaw";
            mac = "02:00:00:00:01:01";
          }
        ];

        shares = [
          {
            source = "/var/lib/microvms/openclaw/secrets";
            mountPoint = "/run/secrets";
            tag = "secrets";
            proto = "virtiofs";
          }
        ];

        volumes = [
          {
            mountPoint = "/var/lib/openclaw-state";
            image = "/var/lib/microvms/openclaw/state.img";
            size = 2048;
          }
        ];
      };

      # ─── Networking in der VM ─────────────────────────────────
      networking.useNetworkd = true;
      networking.useDHCP = false;
      systemd.network.networks."10-eth" = {
        matchConfig.Name = "ether";
        networkConfig = {
          Address = "10.0.100.2/24";
          Gateway = "10.0.100.1";
          DNS = "10.0.100.1";
        };
      };

      # SSH zum Reinkommen
      services.openssh = {
        enable = true;
        settings.PasswordAuthentication = false;
      };

      users.users.openclaw = {
        isNormalUser = true;
        home = "/home/openclaw";
        uid = 1000;
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKY2Gj5cyIxJ1uSkGJuGoOX3lcifjhAHX49mSJ9ENEBR eumel@nixos"
        ];
      };

      # ─── SearXNG ──────────────────────────────────────────────
      services.searx = {
        enable = true;
        package = pkgs.searxng;
        environmentFile = "/run/secrets/searxng-env";
        settings = {
          server = {
            bind_address = "127.0.0.1";
            port = 8080;
            secret_key = "@SEARXNG_SECRET@";
            limiter = false;
          };
          search = {
            safe_search = 0;
            autocomplete = "duckduckgo";
            formats = ["html" "json"]; # KRITISCH
          };
          engines = lib.mapAttrsToList (name: value: {inherit name;} // value) {
            "duckduckgo".disabled = false;
            "google".disabled = false;
            "wikipedia".disabled = false;
            "github".disabled = false;
          };
        };
      };

      systemd.services.searxng-env-prepare = {
        description = "Build SearXNG environment file";
        wantedBy = ["searx.service"];
        before = ["searx.service"];
        serviceConfig.Type = "oneshot";
        script = ''
          echo "SEARXNG_SECRET=$(cat /run/secrets/searxng-secret)" \
            > /run/secrets/searxng-env
          chmod 0400 /run/secrets/searxng-env
        '';
      };

      # ─── OpenClaw ────────────────────────────────────────────
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;

      home-manager.users.openclaw = {...}: {
        imports = [inputs.nix-openclaw.homeManagerModules.openclaw];

        home.stateVersion = "24.11";
        home.enableNixpkgsReleaseCheck = false;

        programs.openclaw = {
          # Bundled plugins toggles
          bundledPlugins = {
            summarize.enable = true; # URL/PDF/Video Summary
          };
          instances.default = {
            enable = true;
            config = {
              gateway = {
                mode = "local";
                auth.token = "/run/secrets/gateway-token";
              };

              # Custom Ollama-Provider für unsere Host-Adresse registrieren
              models = {
                mode = "merge";
                providers = {
                  ollama-host = {
                    api = "openai-completions"; # ← war "type"
                    baseUrl = "http://10.0.100.1:11434/v1";
                    apiKey = "ollama"; # Ollama ignoriert ihn
                    models = [
                      {
                        id = "qwen3:32b";
                        name = "Qwen3 32B (local)";
                        reasoning = true;
                        input = ["text"];
                        contextWindow = 32768;
                        maxTokens = 8192;
                      }
                    ];
                  };
                };
              };

              agents.defaults.model = {
                primary = "ollama-host/qwen3:32b";
                fallbacks = [];
              };

              # WICHTIG: Allowlist — sonst lehnt OpenClaw das Modell ab
              agents.defaults.models = {
                "ollama-host/qwen3:32b" = {
                  alias = "qwen3";
                };
              };
            };
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d /var/lib/openclaw-state 0755 openclaw users -"
        "L+ /home/openclaw/.openclaw - - - - /var/lib/openclaw-state"
      ];
    };
  };
}
