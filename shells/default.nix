{ pkgs }: {
  default = pkgs.mkShell {
    buildInputs = with pkgs; [
      # kubernetes
      kubectl
      k9s

      # services
      go
      gopls
    ];

    shellHook = ''
      export KUBECONFIG=./.kube/config
    '';
  }; 
}
