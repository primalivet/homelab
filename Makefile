switch-macbook-pro:
	darwin-rebuild switch --flake .#macbook-pro

check-macbook-pro:
	darwin-rebuild check --flake .#macbook-pro

update:
	nix flake update

format:
	nix fmt

iso: 
	nix build .#nixosConfigurations.iso-aarch64.config.system.build.isoImage
iso-x86_64: 
	nix build .#nixosConfigurations.iso-x86_64.config.system.build.isoImage

poweroff-all:
	@echo "Powering off homelab3"
	ssh -t gustaf@192.168.1.12 "sudo poweroff"
	ssh -t gustaf@192.168.1.11 "sudo poweroff"
	ssh -t gustaf@192.168.1.10 "sudo poweroff"

agekey-retrive:
	@if [ -z "$(MACHINE_IP)" ]; then \
		echo "MACHINE_IP is not set"; \
		exit 1; \
	fi
	ssh gustaf@$(MACHINE_IP) 'cat /etc/ssh/ssh_host_ed25519_key.pub' | ssh-to-age

connected-install:
	@if [ -z "$(MACHINE_IP)" ]; then \
		echo "MACHINE_IP is not set"; \
		exit 1; \
	fi
	@if [ -z "$(MACHINE_DISK)" ]; then \
		echo "MACHINE_DISK is not set"; \
		exit 1; \
	fi
	@echo "Trying to login to $(MACHINE_IP)"
	scp install-homelab-machine.sh nixos@$(MACHINE_IP):/home/nixos
	ssh nixos@$(MACHINE_IP) "chmod +x install-homelab-machine.sh"
	@echo "Run 'sudo ./install-homelab-machine.sh <machine-name> <machine-disk>' to start the installation."
	ssh nixos@$(MACHINE_IP)

remote-install: install-homelab-machine.sh
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
	scp install-homelab-machine.sh nixos@$(MACHINE_IP):/home/nixos
	ssh nixos@$(MACHINE_IP) "chmod +x install-homelab-machine.sh && sudo ./install-homelab-machine.sh -y $(MACHINE_NAME) $(MACHINE_DISK)"
	ssh nixos@$(MACHINE_IP) "sleep 10 && sudo poweroff"

# TODO: Set default values here for other script arguments, emial, name, etc.
post-install: post-install-homelab-machine.sh
	@if [ -z "$(MACHINE_NAME)" ]; then \
		echo "MACHINE_NAME is not set"; \
		exit 1; \
	fi
	@if [ -z "$(MACHINE_IP)" ]; then \
		echo "MACHINE_IP is not set"; \
		exit 1; \
	fi
	@echo "Trying to do post install $(MACHINE_NAME) on $(MACHINE_IP)"
	./post-install-homelab-machine.sh $(MACHINE_NAME) $(MACHINE_IP)
