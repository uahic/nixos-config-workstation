# modules/ai.nix
#
# Local AI on the two RTX 3090s (Ollama) + Hermes Agent + Claude on demand.
# Replaces modules/ollama.nix (everything that was there is kept below).
#
#   Ollama (CUDA)        127.0.0.1:11434  – serves local models on both 3090s
#   Hermes Agent         systemd service  – defaults to the local model,
#                                           switch to Claude per session/turn
#   Claude               Anthropic API    – pay-per-token, key sops-encrypted
#                                           in secrets/hermes.env
#
# Secrets: the Anthropic key lives encrypted in this repo
# (secrets/hermes.env, sops + age) and is decrypted at activation with your
# existing SSH key, so rebuilds and reinstalls need no manual steps.
# Add or change the key with `sops secrets/hermes.env`.
#
# Usage after the rebuild (log out/in once so the `hermes` group applies):
#
#   hermes                                                    # local qwen3:32b
#   hermes chat --provider anthropic --model claude-sonnet-5-5  # Claude session
#   /model anthropic:claude-opus-5-5                          # switch inside a session
#   /model custom                                             # back to the local model
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  # Local default model. Q4 weights ~20 GB + 64K context with a q8 KV cache
  # (~9 GB) fits comfortably in 2x24 GB, even with the desktop on one card.
  # Swap for any Ollama tag that supports tool calling.
  localModel = "qwen3:32b";

  # Hermes refuses local endpoints with less than 64K context, and Ollama
  # ignores num_ctx sent over its OpenAI-compatible /v1 API, so the window
  # has to be set server-side and kept in sync with Hermes below.
  contextLength = 65536;

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
in {
  imports = [
    inputs.hermes-agent.nixosModules.default
    inputs.sops-nix.nixosModules.sops
  ];

  # ─── Ollama: local inference on both 3090s ─────────────────────────────
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;

    # Kept from modules/ollama.nix. The firewall keeps 11434 closed to the
    # LAN; switch to "127.0.0.1" if nothing outside this host (e.g. the
    # openclaw microVM on br-microvms) needs to reach Ollama.
    host = "0.0.0.0";
    port = 11434;

    # Pulled in the background after Ollama starts.
    loadModels = [localModel];

    environmentVariables = {
      # Kept from modules/ollama.nix: stable PCI ordering, non-display card first.
      CUDA_DEVICE_ORDER = "PCI_BUS_ID";
      CUDA_VISIBLE_DEVICES = "1,0";

      OLLAMA_CONTEXT_LENGTH = toString contextLength;
      OLLAMA_FLASH_ATTENTION = "1"; # required for a quantized KV cache
      OLLAMA_KV_CACHE_TYPE = "q8_0"; # halves KV-cache VRAM, negligible quality loss
      OLLAMA_NUM_PARALLEL = "1"; # each parallel slot reserves a full 64K context
      OLLAMA_MAX_LOADED_MODELS = "1"; # one big model at a time across both cards
      OLLAMA_KEEP_ALIVE = "30m"; # free VRAM for games after 30 idle minutes
    };
  };

  # ─── Hermes Agent ──────────────────────────────────────────────────────
  # Native mode: hardened systemd service as the dedicated `hermes` user
  # (ProtectSystem=strict, writes only to /var/lib/hermes). Container mode is
  # left off on purpose: it wants Docker, which conflicts with Podman's
  # dockerCompat in modules/container.nix.
  services.hermes-agent = {
    enable = true;

    # `hermes` CLI on PATH + system-wide HERMES_HOME, so your shell sessions
    # share sessions, memory and skills with the service.
    addToSystemPackages = true;

    # Decrypted by sops-nix, then merged into $HERMES_HOME/.env.
    environmentFiles = lib.optional hasHermesSecret config.sops.secrets.hermes-env.path;

    settings = {
      # Default: the local model through Ollama's OpenAI-compatible API.
      model = {
        provider = "custom";
        default = localModel;
        base_url = "http://127.0.0.1:${toString config.services.ollama.port}/v1";
        context_length = contextLength;
      };

      # Claude needs no entry here: the built-in `anthropic` provider is
      # enabled by ANTHROPIC_API_KEY from secrets/hermes.env.

      # Optional: fall back to Claude automatically when the local model
      # errors out (5xx, malformed responses). Off by default because every
      # fallback turn is billed to your API key.
      # fallback_providers = [
      #   { provider = "anthropic"; model = claudeModel; }
      # ];
    };

    # Optional: browser dashboard on http://127.0.0.1:9119
    # backend.mode = "dashboard";
  };

  # Lets your user run the `hermes` CLI against the service's shared state
  # (the state dir is 2770 hermes:hermes).
  users.users.eumel.extraGroups = [config.services.hermes-agent.group];

  # ─── Secrets (sops-nix) ────────────────────────────────────────────────
  # Decrypted to /run/secrets/hermes-env (root-only, tmpfs) on activation,
  # before Hermes merges it. Changing the file restarts Hermes.
  sops = {
    age.sshKeyPaths = [sshKey];
    gnupg.sshKeyPaths = [];
    secrets = lib.mkIf hasHermesSecret {
      hermes-env = {
        sopsFile = hermesSecretFile;
        format = "dotenv";
        restartUnits = ["hermes-agent.service"];
      };
    };
  };

  # `sops secrets/hermes.env` decrypts with the same SSH key.
  environment.systemPackages = [pkgs.sops pkgs.ssh-to-age];
  home-manager.users.eumel.home.sessionVariables.SOPS_AGE_KEY_CMD = "${pkgs.ssh-to-age}/bin/ssh-to-age -private-key -i ${sshKey}";

  # Hermes talks to Ollama on loopback, so start it after Ollama.
  systemd.services.hermes-agent = {
    wants = ["ollama.service"];
    after = ["ollama.service"];
  };

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
