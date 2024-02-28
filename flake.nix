{
  description = "Flake for building a Raspberry Pi Zero 2 SD image";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    nixos-hardware.url = "github:NixOS/nixos-hardware";
  };

  outputs = {
    self,
    nixpkgs,
    deploy-rs,
    nixos-hardware
  }:
    let
      # see https://github.com/NixOS/nixpkgs/issues/154163
      overlays = [
        (final: super: {
          makeModulesClosure = x:
            super.makeModulesClosure (x // { allowMissing = true; });
        })
      ];
      in rec {
        nixosConfigurations = {
          # zero2w = nixpkgs.lib.nixosSystem {
          #   modules = [
          #     "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          #     ./zero2w.nix
          #   ];
          # };
          locknix = nixpkgs.lib.nixosSystem {
            modules = [
              "${nixos-hardware}/raspberry-pi/4"
              ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
              "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
              ./zero2w.nix
            ];
          };
        };
          
        deploy = {
          user = "root";
          nodes = {
            # zero2w = {
            #   hostname = "zero2w";
            #   profiles.system.path =
            #     deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.zero2w;
            #     #deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.zero2w;
            #   #remoteBuild = true;
            
            # };
            locknix = {
              hostname = "locknix";
              profiles.system.path =
                deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.locknix;
              #deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.zero2w;
              #remoteBuild = true;
              
            };
          };
        };
      };
}
