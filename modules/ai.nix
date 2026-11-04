# modules/ai.nix
#
# Local AI on the two RTX 3090s (Ollama) + Hermes Agent + Claude on demand.
# Replaces modules/ollama.nix (everything that was there is kept below).
#
#   Ollama (CUDA)        127.0.0.1:11434  – serves local models on both 3090s
#   Hermes Agent         as user eumel    – Home Manager module, ~/.hermes;
#                                           local model by default, Claude on demand
#   Hermes Dashboard     127.0.0.1:9119   – web UI (+ Memory Wiki / Obsidian tabs)
#   Hermes Desktop       app launcher     – native UI
#   Hermes browser       127.0.0.1:9222   – Brave with CDP, used by the browser tools
#   Claude               Anthropic API    – pay-per-token, key sops-encrypted
#                                           in secrets/hermes.env
#
# Ollama comes from its own flake input (`nixpkgs-ollama`), so it can be
# updated on its own without moving the rest of the system:
#
#   nix flake update nixpkgs-ollama && sudo nixos-rebuild switch --flake .#nixos
#
# Secrets: the Anthropic key lives encrypted in this repo
# (secrets/hermes.env, sops + age) and is decrypted at activation with your
# existing SSH key, so rebuilds and reinstalls need no manual steps.
# Add or change the key with `sops secrets/hermes.env`.
#
# Usage after the rebuild (log out/in once so HERMES_HOME=~/.hermes applies):
#
#   hermes                                                    # local model
#   hermes chat --provider anthropic --model claude-sonnet-5-5  # Claude session
#   /model anthropic:claude-opus-5-5                          # switch inside a session
#   /model custom                                             # back to the local model
#   xdg-open http://127.0.0.1:9119                            # dashboard
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # Separate nixpkgs just for Ollama: new model architectures (e.g. Qwen3.8)
  # need a recent Ollama, and the registry refuses pulls from older servers
  # with "412: requires a newer version of Ollama".
  pkgs-ollama = import inputs.nixpkgs-ollama {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true; # CUDA
  };

  # Local default model. Qwen3.8-27B at Q8_0: ~30 GB weights, near-lossless.
  # Qwen3.8 is a hybrid architecture with a small KV cache, so 64K context
  # with a q8 KV cache still fits in 2x24 GB, even with the desktop on one
  # card. Use "qwen3.8:27b" (Q4, ~18 GB) if you need the VRAM for something else.
  # Swap for any Ollama tag that supports tool calling.
  #localModel = "qwen3.8:27b-q8_0";
  localModel = "hf.co/empero-ai/Qwen3.8-35B-A3B-Distill-GGUF:Q4_K_M";

  # Hermes refuses local endpoints with less than 64K context, and Ollama
  # ignores num_ctx sent over its OpenAI-compatible /v1 API, so the window
  # has to be set server-side and kept in sync with Hermes below.
  #contextLength = 65536;
  contextLength = 262144;

  # Claude models, used only when you switch to them.
  claudeModel = "claude-sonnet-5-5";

  # Encrypted secrets file (see .sops.yaml). Until it exists, Hermes simply
  # runs local-only; nothing breaks. Flakes only see git-tracked files, so
  # `git add` it after creating it.
  hermesSecretFile = ../secrets/hermes.env;
  hasHermesSecret = builtins.pathExists hermesSecretFile;

  # Decrypts the secrets at activation. Must be a key without a passphrase;
  # its public half is the recipient in .sops.yaml.
  sshKey = "/home/eumel/.ssh/id_ed25519";

  # ─── Hermes plugins (pinned to the commits reviewed for the catalog) ──
  # First build fails with "hash mismatch ... got: sha256-…": paste that
  # hash in place of lib.fakeHash and rebuild (once per plugin).

  # Memory Wiki (official): dashboard tab with subject pages, daily logs and
  # a read-only view of MEMORY.md / USER.md. Lives in a subdirectory of the
  # official plugins repo, so it is copied out into its own package.
  memoryWikiSrc = pkgs.fetchFromGitHub {
    owner = "NousResearch";
    repo = "hermes-official-plugins";
    rev = "54afaf5014db23346148436c4883eb64095e8060";
    hash = "sha256-PJaSr3n5RBhMbQZrC0AQ29OurzUBj6vSyMbZgfxWAXA=";
  };
  memoryWikiPlugin = pkgs.runCommand "memory-wiki" {} ''
    cp -r ${memoryWikiSrc}/memory-wiki $out
  '';

  # Obsidian Memory (community): OBSIDIAN tab in the dashboard to browse,
  # search and edit vault notes, with a graph view.
  obsidianMemoryPlugin = pkgs.fetchFromGitHub {
    owner = "kyssta-exe";
    repo = "hermes-obsidian-memory";
    rev = "11239984e82caa6dbf02106ce315e3019368b5fc";
    hash = "sha256-cjafixqPnhddAzQ3IbiMHs6Zi6MXYy44ruv1GG49h40=";
  };

  # Your Obsidian vault. The plugin also scans sibling directories of this
  # path, ~/Documents/Obsidian/, ~/obsidian-vaults/ and ~/vaults/.
  # obsidianVault = "/home/eumel/Documents/Obsidian";
  obsidianVault = "/data/obsidian";

  # ─── Browser for the Hermes browser tools ─────────────────────────────
  # Browsers installed through GNOME Software are Flatpaks: sandboxed and
  # outside every path Hermes searches, and they can't open a debug port to
  # the host properly. So Hermes gets its own Nix-managed Brave with the
  # Chrome DevTools Protocol on 127.0.0.1:9222 and a separate profile
  # (~/.hermes/chrome-debug); your normal Brave/Chromium stay untouched.
  # pkgs.chromium works the same way (binary: bin/chromium).
  hermesBrowser = pkgs.brave;
  hermesBrowserBin = "${hermesBrowser}/bin/brave";
  cdpPort = 9222;
  # true: invisible, runs always (also at night for cron jobs, no login needed).
  # false: visible window in your desktop session, so you can watch the agent.
  browserHeadless = true;
in {
  imports = [inputs.sops-nix.nixosModules.sops];

  # ─── Ollama: local inference on both 3090s ─────────────────────────────
  services.ollama = {
    enable = true;
    # From the nixpkgs-ollama input (see top of file). The module also puts
    # this package on PATH, so the `ollama` CLI matches the server version.
    package = pkgs-ollama.ollama-cuda;

    # Kept from modules/ollama.nix. The firewall keeps 11434 closed to the
    # LAN; switch to "127.0.0.1" if nothing outside this host (e.g. the
    # openclaw microVM on br-microvms) needs to reach Ollama.
    host = "0.0.0.0";
    port = 11434;

    user = "ollama";
    group = "ollama";

    # Pulled in the background after Ollama starts.
    loadModels = [localModel];

    environmentVariables = {
      # Kept from modules/ollama.nix: stable PCI ordering, non-display card first.
      CUDA_DEVICE_ORDER = "PCI_BUS_ID";
      CUDA_VISIBLE_DEVICES = "1,0";

      OLLAMA_CONTEXT_LENGTH = toString contextLength;
      OLLAMA_FLASH_ATTENTION = "1"; # required for a quantized KV cache
      OLLAMA_KV_CACHE_TYPE = "q8_0"; # halves KV-cache VRAM, negligible quality loss
      OLLAMA_NUM_PARALLEL = "1"; # each parallel slot reserves a full context window
      OLLAMA_MAX_LOADED_MODELS = "1"; # one big model at a time across both cards
      OLLAMA_KEEP_ALIVE = "15m"; # free VRAM for games after 15 idle minutes
    };
  };

  # ─── Hermes Agent ──────────────────────────────────────────────────────
  # Runs as you (Home Manager module), the setup upstream recommends for a
  # personal machine: the `hermes` CLI talks to its own state in ~/.hermes,
  # and the config stays declarative (`hermes setup` / `config set` are
  # blocked; change it here and rebuild). Note: the agent has your user's
  # permissions, unlike a separate system user.
  home-manager.users.eumel = {
    imports = [inputs.hermes-agent.homeManagerModules.default];

    programs.hermes-agent = {
      # `hermes` on PATH + HERMES_HOME=~/.hermes for your shells.
      enable = true;
      # Hermes Desktop (native app, launcher entry in the app menu).
      desktop.enable = true;
    };

    # Hermes' browser on PATH too, so `/browser connect` in the CLI finds it.
    # The Flatpak Brave/Chromium can stay or go; Hermes doesn't use them.
    home.packages = [hermesBrowser];

    # Brave with CDP for the Hermes browser tools (see let block above).
    systemd.user.services.hermes-browser = {
      Unit =
        {
          Description = "Brave with remote debugging for Hermes Agent";
        }
        // lib.optionalAttrs (!browserHeadless) {
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };
      Service = {
        ExecStart = lib.concatStringsSep " " ([
            hermesBrowserBin
            "--remote-debugging-address=127.0.0.1"
            "--remote-debugging-port=${toString cdpPort}"
            "--user-data-dir=%h/.hermes/chrome-debug"
            "--no-first-run"
            "--no-default-browser-check"
          ]
          ++ lib.optional browserHeadless "--headless=new");
        Restart = "on-failure";
        RestartSec = 5;
      };
      Install.WantedBy =
        if browserHeadless
        then ["default.target"]
        else ["graphical-session.target"];
    };

    services.hermes-agent = {
      enable = true;

      # Background gateway (systemd user service): scheduled/cron jobs,
      # messaging platforms (Telegram/Discord/Slack, tokens go into
      # secrets/hermes.env), and `hermes chat` attaches to it.
      gateway.enable = true;

      # Web dashboard on http://127.0.0.1:9119, next to the gateway. Both
      # plugins below add their tabs here. Loopback only: no auth needed.
      backend = {
        mode = "dashboard";
        port = 9119;
      };

      # Plugins: symlinked into ~/.hermes/plugins on activation. Removing one
      # here and rebuilding removes it again. Each also has to be listed in
      # settings.plugins.enabled below.
      extraPlugins = [
        memoryWikiPlugin
        obsidianMemoryPlugin
      ];

      # Non-secret env vars, merged into ~/.hermes/.env (visible in the store).
      environment = {
        OBSIDIAN_VAULT_PATH = obsidianVault;
      };

      # Decrypted by sops-nix, merged into ~/.hermes/.env on activation.
      environmentFiles = lib.optional hasHermesSecret config.sops.secrets.hermes-env.path;

      settings = {
        # Default: the local model through Ollama's OpenAI-compatible API.
        model = {
          provider = "custom";
          default = localModel;
          base_url = "http://127.0.0.1:${toString config.services.ollama.port}/v1";
          context_length = contextLength;
          ollama_num_ctx = contextLength;
        };

        # Names from each plugin's plugin.yaml (not the repo names).
        plugins.enabled = [
          "memory-wiki"
          "obsidian-memory"
        ];

        # Browser tools drive the Brave instance from hermes-browser above,
        # for every session (CLI, gateway, dashboard), not only after a
        # manual `/browser connect`.
        browser.cdp_url = "http://127.0.0.1:${toString cdpPort}";

        # Claude needs no entry here: the built-in `anthropic` provider is
        # enabled by ANTHROPIC_API_KEY from secrets/hermes.env.

        # Optional: fall back to Claude automatically when the local model
        # errors out (5xx, malformed responses). Off by default because every
        # fallback turn is billed to your API key.
        # fallback_providers = [
        #   { provider = "anthropic"; model = claudeModel; }
        # ];
      };
    };
  };

  # Keeps your systemd user manager (and with it the Hermes gateway,
  # dashboard and headless browser) running when you are logged out,
  # e.g. for cron jobs at night.
  users.users.eumel.linger = true;

  # ─── Secrets (sops-nix) ────────────────────────────────────────────────
  # Decrypted to /run/secrets/hermes-env (tmpfs, readable only by eumel) on
  # activation, before Home Manager merges it into ~/.hermes/.env.
  sops = {
    age.sshKeyPaths = [sshKey];
    gnupg.sshKeyPaths = [];
    secrets = lib.mkIf hasHermesSecret {
      hermes-env = {
        sopsFile = hermesSecretFile;
        format = "dotenv";
        owner = "eumel";
      };
    };
  };

  # `sops secrets/hermes.env` decrypts with the same SSH key.
  environment.systemPackages = [pkgs.sops pkgs.ssh-to-age];
  home-manager.users.eumel.home.sessionVariables.SOPS_AGE_KEY_CMD = "${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i ${sshKey}";

  # ─── Optional: cap both 3090s at 280 W ─────────────────────────────────
  # A few percent slower inference for much less heat and fewer PSU spikes.
  # Also applies while gaming, hence off by default.
  # systemd.services.nvidia-power-limit = {
  #   description = "Set NVIDIA GPU power limit";
  #   wantedBy = ["multi-user.target"];
  #   after = ["systemd-modules-load.service"];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 280";
  #   };
  # };
}
