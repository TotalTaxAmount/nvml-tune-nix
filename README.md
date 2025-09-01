# Nvidia NVML OC Nixos
This flake makes it easy to overclock Nvidia GPUs on NixOS.

Usage:
Add this flake to your flake.nix:
```nix
nvml-tune.url = "github:TotalTaxAmount/nvml-tune-nix";
```

Then in your configuration:
```nix
services.nvml = {
  enable = true;
  gpus."0" = { # Nvidia GPU id (from nvidia-smi)
    clockOffset = 110;
    memOffset = 1800; # Needs to be 2x target (ex: 900Mhz offset = 1800 here)
    powerLimit = 310000;
  };
};
```