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
  }@inputs:
    let
      # see https://github.com/NixOS/nixpkgs/issues/154163
      overlays = [
        (final: super: {
          makeModulesClosure = x:
            super.makeModulesClosure (x // { allowMissing = true; });
        })
      ];
      specialArgs = {
        inherit nixos-hardware inputs;
      };
    in rec {
      nixosConfigurations = {
        zerow = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-raspberrypi-installer.nix"
            ./zerow.nix
          ];
        };
        zero2w = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ./zero2w.nix
          ];
        };
        pi4 = nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = overlays; })
            "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ./pi4.nix
          ];
        };
      };
          
      deploy = {
        user = "root";
        nodes = {
          zero2w = {
            hostname = "nix-zero2w";
            profiles.system.path =
              deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.zero2w;
            #deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.zero2w;
            #remoteBuild = true;
            
          };
          pi4 = {
            hostname = "nix-pi4";
            profiles.system.path =
              deploy-rs.lib.aarch64-linux.activate.nixos self.nixosConfigurations.pi4;
            #deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.zero2w;
            #remoteBuild = true;
            
          };
        };
      };
    };
}
