# Makefile for building custom Talos images with CONFIG_IPV6_MROUTE enabled

# Configuration
TALOS_VERSION ?= v1.12.1
PKGS_REF ?= release-1.12
REGISTRY ?= ghcr.io/addono
PLATFORM ?= linux/amd64
PUSH ?= false

# Derived variables
KERNEL_IMAGE := $(REGISTRY)/talos-kernel:$(TALOS_VERSION)
INSTALLER_IMAGE := $(REGISTRY)/talos-installer:$(TALOS_VERSION)
PKGS_DIR := _out/pkgs

.PHONY: all
all: installer

.PHONY: help
help:
	@echo "Talos Custom Image Builder"
	@echo ""
	@echo "Targets:"
	@echo "  clone-pkgs      - Clone siderolabs/pkgs repository"
	@echo "  patch-kernel    - Patch kernel config to enable CONFIG_IPV6_MROUTE"
	@echo "  kernel          - Build custom kernel"
	@echo "  installer       - Build custom Talos installer image"
	@echo "  clean           - Clean build artifacts"
	@echo ""
	@echo "Variables:"
	@echo "  TALOS_VERSION   - Talos version (default: $(TALOS_VERSION))"
	@echo "  PKGS_REF        - pkgs repository ref (default: $(PKGS_REF))"
	@echo "  REGISTRY        - Container registry (default: $(REGISTRY))"
	@echo "  PLATFORM        - Build platform (default: $(PLATFORM))"
	@echo "  PUSH            - Push images (default: $(PUSH))"

.PHONY: clone-pkgs
clone-pkgs:
	@echo "==> Cloning siderolabs/pkgs repository..."
	@if [ ! -d "$(PKGS_DIR)" ]; then \
		mkdir -p $(PKGS_DIR) && \
		git clone --depth 1 --branch $(PKGS_REF) \
			https://github.com/siderolabs/pkgs.git $(PKGS_DIR); \
	else \
		echo "pkgs repository already cloned"; \
	fi

.PHONY: patch-kernel
patch-kernel: clone-pkgs
	@echo "==> Patching kernel configuration..."
	@./scripts/patch-kernel-config.sh $(PKGS_DIR)

.PHONY: kernel
kernel: patch-kernel
	@echo "==> Building custom kernel..."
	@echo "This requires Docker with BuildKit support"
	@cd $(PKGS_DIR) && \
		make kernel REGISTRY=$(REGISTRY) PUSH=$(PUSH) PLATFORM=$(PLATFORM)

.PHONY: installer
installer: kernel
	@echo "==> Building Talos installer with custom kernel..."
	@./scripts/build-installer.sh $(TALOS_VERSION) $(KERNEL_IMAGE) $(INSTALLER_IMAGE) $(PLATFORM) $(PUSH)

.PHONY: clean
clean:
	@echo "==> Cleaning build artifacts..."
	@rm -rf $(PKGS_DIR)
	@rm -rf _out

.PHONY: verify
verify:
	@echo "==> Verifying kernel configuration..."
	@./scripts/verify-config.sh $(PKGS_DIR)
