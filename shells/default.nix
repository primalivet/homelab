{ pkgs }: {
  default = pkgs.mkShell {
    buildInputs = with pkgs; [
      kubectl
      k9s
    ];

    shellHook = ''
      export KUBECONFIG=./.kube/config
    '';
  }; 
}
