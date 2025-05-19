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
        aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;
        aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.nixpkgs-fmt;
      };

      nixosConfigurations = {
        homelab1 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./machines/homelab1/configuration.nix
          ];
        };

        vm-homelab1 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            ./machines/vm-homelab1/configuration.nix
          ];
        };

        iso-aarch64 = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = [
            (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
            {
              users.users.nixos = {
                openssh.authorizedKeys.keys = [
                  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDp7yzlnHtcS7TliFQcaHKiojr6frzHsZ62F5kp62eeE0mmACB4vnwvWF+z6jusZpqZ1vNej5Sjh6O1phj4igtTQ5OV+D9imbhBmFvGfP9hvaIvWgdqBipeJ454u9G8n7rx9rgiPekzJfNuCpjRqJrDdc8upQJfTZTVzuDjA3yPg4rVq9L4wJWBZUzukzDEKRjrkmXE6Cuwa5xUhpViedz49+IIQypSXT/v3REnrsCO0qNm45kXhEMFH9qv12HS56jZW6ndx+OJjfhXyab8UChivFiAt/QpF3bdhtRCJ74M0bAFSsAb3UhGJ/37mslatZUH0NQpQdzIrWpzIYUFMAmKPN0pyOEzo7IVMlSdD9Tm8DkpeXPv8qDF/CBo6ms7FpDqPKm+J2kH9V7lo88Jm0FjFLYBGXcTv4a92o+nkYAB0Ga/thhbqL/Q2Zmjf+0X8S2QL5v7hey9HmVNV60hAn0merFesg2BX7oVp7QxyvUy8Vj1GnB41Ph2BSFvLhShpW8= gustaf@Gustafs-MacBook-Pro.local"
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJm0n5LCXPRWjIRLxILZmmeWzDXjjuVD8UFoWLrXNu9 gustaf.holm@icloud.com"
                ];
              };
            }
          ];
        };

        iso-x86_64 = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")
            {
              users.users.nixos = {
                openssh.authorizedKeys.keys = [
                  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDp7yzlnHtcS7TliFQcaHKiojr6frzHsZ62F5kp62eeE0mmACB4vnwvWF+z6jusZpqZ1vNej5Sjh6O1phj4igtTQ5OV+D9imbhBmFvGfP9hvaIvWgdqBipeJ454u9G8n7rx9rgiPekzJfNuCpjRqJrDdc8upQJfTZTVzuDjA3yPg4rVq9L4wJWBZUzukzDEKRjrkmXE6Cuwa5xUhpViedz49+IIQypSXT/v3REnrsCO0qNm45kXhEMFH9qv12HS56jZW6ndx+OJjfhXyab8UChivFiAt/QpF3bdhtRCJ74M0bAFSsAb3UhGJ/37mslatZUH0NQpQdzIrWpzIYUFMAmKPN0pyOEzo7IVMlSdD9Tm8DkpeXPv8qDF/CBo6ms7FpDqPKm+J2kH9V7lo88Jm0FjFLYBGXcTv4a92o+nkYAB0Ga/thhbqL/Q2Zmjf+0X8S2QL5v7hey9HmVNV60hAn0merFesg2BX7oVp7QxyvUy8Vj1GnB41Ph2BSFvLhShpW8= gustaf@Gustafs-MacBook-Pro.local"
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJm0n5LCXPRWjIRLxILZmmeWzDXjjuVD8UFoWLrXNu9 gustaf.holm@icloud.com"
                ];
              };
            }
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
