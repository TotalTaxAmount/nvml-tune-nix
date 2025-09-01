{
  description = "NixOS module for GPU overclock via NVML";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    nixosModules.nvml = import ./modules/nvml.nix;
  };
}
