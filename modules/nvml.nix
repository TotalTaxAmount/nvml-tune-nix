{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nvml;

  pythonNvml = pkgs.python311.withPackages (ps: with ps; [
    nvidia-ml-py
  ]);

  gpuModule = types.submodule {
    options = {
      clockOffset = mkOption {
        type = types.int;
        default = 0;
        description = "Core clock offset in MHz";
      };
      memOffset = mkOption {
        type = types.int;
        default = 0;
        description = "Memory clock offset in MHz (must be doubled for NVML. Ex: For 900Mhz offset -> set to 1800)";
      };
      powerLimit = mkOption {
        type = types.int;
        default = 0;
        description = "Power limit in milliwatts (0 = skip)";
      };
    };
  };
in {
  options.services.nvml = {
    enable = mkEnableOption "NVML GPU tuning service";

    gpus = mkOption {
      type = types.attrsOf gpuModule;
      default = {};
      description = "Per-GPU NVML tuning configuration, keyed by GPU index (as a string).";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pythonNvml ];

    systemd.services = mapAttrs' (gpuIndex: gpuCfg:
      nameValuePair "nvml-tune-${gpuIndex}" {
        description = "NVML GPU tuning for GPU ${gpuIndex}";
        wantedBy = [ "multi-user.target" ];
        after = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pythonNvml}/bin/python3 ${pkgs.writeText "nvml-tune-${gpuIndex}.py" ''
            from pynvml import *
            import sys

            CORE_OFFSET = ${toString gpuCfg.clockOffset}
            MEM_OFFSET = ${toString gpuCfg.memOffset}
            POWER_LIMIT = ${toString gpuCfg.powerLimit}
            GPU_INDEX = ${gpuIndex}

            try:
                nvmlInit()
                h = nvmlDeviceGetHandleByIndex(GPU_INDEX)
                nvmlDeviceSetGpcClkVfOffset(h, CORE_OFFSET)
                nvmlDeviceSetMemClkVfOffset(h, MEM_OFFSET)
                if POWER_LIMIT != 0:
                    max_pl = nvmlDeviceGetPowerManagementLimitConstraints(h)[1]
                    nvmlDeviceSetPowerManagementLimit(h, min(POWER_LIMIT, max_pl))
                nvmlShutdown()
                print(f"[info] Success for GPU {GPU_INDEX}: core_offset={CORE_OFFSET}, mem_offset={MEM_OFFSET}, power_limit={POWER_LIMIT}")
            except Exception as e:
                print(f"[error] NVML tuning failed for GPU {GPU_INDEX}:", e, file=sys.stderr)
                sys.exit(1)
          ''}";
        };
      }
    ) cfg.gpus;
  };
}
