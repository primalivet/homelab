update:
	nix flake update

format:
	nix fmt

iso-aarch64: 
	nix build .#nixosConfigurations.iso-aarch64.config.system.build.isoImage

iso-x86_64: 
	nix build .#nixosConfigurations.iso-x86_64.config.system.build.isoImage

k8s-deploy:
	# WHY: Apply kubernetes secrets from a sops encrypted file.
	# - Kustomization 'secretGenerator' can use file outside kustomization
	#   directory if no --load-restrict flag is set. Sops generate FIFO or
	#   non FIFO elsewhere.
	kubectl create secret generic homelab-secrets --dry-run=client --from-env-file=<(sops -d .secret.env) -o yaml | kubectl apply -f -
	kubectl apply -k ./kubernetes

machine-shutdown-all:
	@echo "Draining Kubernetes nodes..."
	kubectl drain homelab2 --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 || true
	kubectl drain homelab3 --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 || true
	kubectl drain homelab1 --ignore-daemonsets --delete-emptydir-data --force --grace-period=30 || true
	@echo "Powering off machines..."
	ssh -t gustaf@192.168.1.12 "sudo poweroff" || true
	ssh -t gustaf@192.168.1.11 "sudo poweroff" || true  
	ssh -t gustaf@192.168.1.10 "sudo poweroff" || true
	@echo "Shutdown complete"

machine-retrive-agekey:
	@if [ -z "$(MACHINE_IP)" ]; then \
		echo "MACHINE_IP is not set"; \
		exit 1; \
	fi
	ssh gustaf@$(MACHINE_IP) 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age

machine-connected-install:
	@if [ -z "$(MACHINE_IP)" ]; then \
		echo "MACHINE_IP is not set"; \
		exit 1; \
	fi
	@if [ -z "$(MACHINE_DISK)" ]; then \
		echo "MACHINE_DISK is not set"; \
		exit 1; \
	fi
	@echo "Trying to login to $(MACHINE_IP)"
	scp ./scripts/install-homelab-machine.sh nixos@$(MACHINE_IP):/home/nixos
	ssh nixos@$(MACHINE_IP) "chmod +x install-homelab-machine.sh"
	@echo "Run 'sudo ./install-homelab-machine.sh <machine-name> <machine-disk>' to start the installation."
	ssh nixos@$(MACHINE_IP)

machine-remote-install: 
	@if [ -z "$(MACHINE_NAME)" ]; then \
		echo "MACHINE_NAME is not set"; \
		exit 1; \
	fi
	@if [ -z "$(MACHINE_IP)" ]; then \
		echo "MACHINE_IP is not set"; \
		exit 1; \
	fi
	@if [ -z "$(MACHINE_DISK)" ]; then \
		echo "MACHINE_DISK is not set"; \
		exit 1; \
	fi
	@echo "Trying to installing $(MACHINE_NAME) on disk $(MACHINE_DISK) on host $(MACHINE_IP)"
	scp ./scripts/install-homelab-machine.sh nixos@$(MACHINE_IP):/home/nixos
	ssh nixos@$(MACHINE_IP) "chmod +x install-homelab-machine.sh && sudo ./install-homelab-machine.sh -y $(MACHINE_NAME) $(MACHINE_DISK)"
	ssh nixos@$(MACHINE_IP) "sleep 10 && sudo poweroff"

# TODO: Set default values here for other script arguments, emial, name, etc.
machine-post-install:
	@if [ -z "$(MACHINE_NAME)" ]; then \
		echo "MACHINE_NAME is not set"; \
		exit 1; \
	fi
	@if [ -z "$(MACHINE_IP)" ]; then \
		echo "MACHINE_IP is not set"; \
		exit 1; \
	fi
	@echo "Trying to do post install $(MACHINE_NAME) on $(MACHINE_IP)"
	./scripts/post-install-homelab-machine.sh $(MACHINE_NAME) $(MACHINE_IP)
