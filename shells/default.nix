{ pkgs }: {
  default = pkgs.mkShell {
    buildInputs = with pkgs; [
      yq
      ssh-to-age

      # certificates
      openssl

      # kubernetes
      kubectl
      k9s

      # services
      go
      gopls
      postgresql

      # testing
      pyright
      python3
      python3Packages.locust
    ];
  };
}
