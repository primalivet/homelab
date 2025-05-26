{ pkgs }: {
  default = pkgs.mkShell {
    buildInputs = with pkgs; [
      ssh-to-age

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
