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
        mem = 2048;

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
        matchConfig.Name = "eth*";
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
        imports = [inputs.nix-openclaw.homeManagerModules.default];

        home.stateVersion = "24.11";

        programs.openclaw.instances.default = {
          enable = true;
          config = {
            gateway = {
              mode = "local";
              bind = "loopback";
              auth.token = "/run/secrets/gateway-token";
            };

            agents.defaults.model = {
              provider = "ollama";
              baseUrl = "http://10.0.100.1:11434/v1";
              #primary  = "llama3.1:8b";   # ← dein gepulltes Modell
              primary = "qwen3:32b";
              apiKey = "ollama";
            };

            plugins.web-search = {
              enable = true;
              provider = "searxng";
              searxng = {
                baseUrl = "http://127.0.0.1:8080";
                format = "json";
              };
            };

            toolSecurity = "allowlist";
            toolAllowlist = [
              "read"
              "write"
              "edit"
              "web_search"
              "web_fetch"
              "message"
            ];
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
