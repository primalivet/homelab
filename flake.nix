{
  description = "System configuration flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs@{ self, nixpkgs, ... }:
    let
      mkShell = system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        import ./shells { inherit pkgs; };
    in
    {
      formatter = {
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixpkgs-fmt;
        aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;
        x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      };

      nixosConfigurations = {
        homelab1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/homelab1/configuration.nix
          ];
        };

        homelab2 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/homelab2/configuration.nix
          ];
        };

        vm-homelab1 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./machines/vm-homelab1/configuration.nix
          ];
        };

        vm-homelab2 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./machines/vm-homelab2/configuration.nix
          ];
        };

        iso-aarch64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
            ./modules/homelab-iso.nix
          ];
        };

        iso-x86_64 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
            ./modules/homelab-iso.nix
          ];
        };

      };


      devShells = {
        aarch64-darwin = mkShell "aarch64-darwin";
        aarch64-linux = mkShell "aarch64-linux";
        x86_64-linux = mkShell "x86_64-linux";
      };
    };
}
