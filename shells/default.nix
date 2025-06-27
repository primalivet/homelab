{ pkgs }: {
  default = pkgs.mkShell {
    buildInputs = with pkgs; [
      just
      yq
      ssh-to-age
      podman
      podman-compose

      # certificates
      openssl

      # kubernetes
      fluxcd
      kubectl
      k9s

      # services
      go
      gopls
      postgresql
      sqlc

      # testing
      pyright
      python3
      python3Packages.locust
    ];
  };
}
