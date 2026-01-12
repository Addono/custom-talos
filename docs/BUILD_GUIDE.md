# Building Custom Talos Images - Extended Guide

This document provides detailed information on building custom Talos Linux images with modified kernel configurations.

## Overview

This repository provides tools and automation to build Talos Linux with `CONFIG_IPV6_MROUTE` enabled. There are two approaches:

### Approach 1: Full Kernel Build (Production)

This approach builds a complete custom kernel from the `siderolabs/pkgs` repository.

**Pros:**
- Complete control over kernel configuration
- Produces proper Talos-compatible images
- Can be used in production

**Cons:**
- Resource-intensive (requires powerful CI runners)
- Time-consuming (can take hours to build)
- Requires significant disk space and memory

**Requirements:**
- GitHub Actions with self-hosted runners (recommended) OR GitHub Actions with extended build time
- Docker with BuildKit support
- Significant build resources (8+ GB RAM, 50+ GB disk space)

### Approach 2: Imager-based Build (Demonstration)

This approach uses the Talos imager with documentation showing the kernel patch.

**Pros:**
- Fast builds
- Demonstrates the required changes
- Works with standard GitHub Actions runners

**Cons:**
- Does not produce a fully functional custom kernel
- Requires manual kernel build or external kernel package

## Build Process Details

### Step 1: Clone and Patch

The process starts by cloning the `siderolabs/pkgs` repository and patching the kernel configuration:

```bash
# Clone the repository
git clone --depth 1 --branch release-1.8 https://github.com/siderolabs/pkgs.git

# Run the patch script
./scripts/patch-kernel-config.sh pkgs/

# Verify the patch
./scripts/verify-config.sh pkgs/
```

### Step 2: Build the Kernel

**Option A: Using Make (Recommended)**

```bash
cd pkgs/
make kernel REGISTRY=ghcr.io/yourname PUSH=true PLATFORM=linux/amd64
```

This builds and pushes a container image with the custom kernel.

**Option B: Using Docker Buildx directly**

```bash
cd pkgs/kernel
docker buildx build \
  --platform linux/amd64 \
  --tag ghcr.io/yourname/kernel:v1.8.2-custom \
  --push \
  .
```

### Step 3: Build Talos Artifacts

Once you have a custom kernel image, you need to build the Talos artifacts:

```bash
git clone https://github.com/siderolabs/talos.git
cd talos/

# Build kernel and initramfs
make kernel initramfs \
  PKG_KERNEL=ghcr.io/yourname/kernel:v1.8.2-custom \
  PLATFORM=linux/amd64

# This produces:
# - _out/vmlinuz-amd64
# - _out/initramfs-amd64.xz
```

### Step 4: Build Installer Image

```bash
make imager \
  PKG_KERNEL=ghcr.io/yourname/kernel:v1.8.2-custom \
  PLATFORM=linux/amd64 \
  INSTALLER_ARCH=amd64
```

This produces the installer image at `_out/installer-amd64.tar`.

### Step 5: Publish the Image

```bash
# Load the installer image
docker load -i _out/installer-amd64.tar

# Tag it
docker tag ghcr.io/siderolabs/installer:latest \
  ghcr.io/yourname/talos-installer:v1.8.2-ipv6mroute

# Push it
docker push ghcr.io/yourname/talos-installer:v1.8.2-ipv6mroute
```

## Using the Custom Image

### For New Installations

```bash
talosctl gen config my-cluster https://cluster-endpoint:6443 \
  --install-image ghcr.io/yourname/talos-installer:v1.8.2-ipv6mroute
```

### For Upgrades

```bash
talosctl upgrade \
  --image ghcr.io/yourname/talos-installer:v1.8.2-ipv6mroute \
  --nodes <node-ip>
```

### Verify the Configuration

After the node boots with your custom image:

```bash
# Check that CONFIG_IPV6_MROUTE is enabled
talosctl -n <node-ip> read /proc/config.gz | gunzip | grep CONFIG_IPV6_MROUTE
# Should output: CONFIG_IPV6_MROUTE=y

# Test the Thread Border Router
kubectl logs deployments/thread
# Should not see "Protocol not available" errors
```

## GitHub Actions Automation

The repository includes a GitHub Actions workflow (`.github/workflows/build.yml`) that automates the build process.

### Current Implementation

The current workflow:
1. ✅ Clones siderolabs/pkgs
2. ✅ Patches kernel configuration
3. ✅ Verifies the patch
4. ⚠️  Creates a demonstration image (not a full kernel build)

### Full Implementation (Requires Self-Hosted Runners)

To enable full kernel builds in GitHub Actions:

1. Set up self-hosted runners with:
   - 8+ GB RAM
   - 50+ GB disk space
   - Docker with BuildKit enabled

2. Update the workflow to uncomment the actual kernel build commands

3. Configure secrets:
   - `GHCR_TOKEN`: GitHub token with package write permissions

### Manual Trigger

You can manually trigger the workflow with custom versions:

1. Go to Actions → Build Custom Talos Images
2. Click "Run workflow"
3. Enter desired Talos version and pkgs ref
4. Click "Run workflow"

## Resource Requirements

### Local Build

- **CPU**: 4+ cores recommended
- **RAM**: 8+ GB
- **Disk**: 50+ GB free space
- **Time**: 2-4 hours for full build

### GitHub Actions (Standard Runners)

- Limited by GitHub's runner constraints
- Full kernel build not recommended on standard runners
- Use for verification and testing only

### GitHub Actions (Self-Hosted Runners)

- Configure runners with adequate resources
- Enable Docker with BuildKit
- Consider using caching to speed up subsequent builds

## Troubleshooting

### Build Fails with "Out of Memory"

Increase available RAM or use a machine with more memory. Building the kernel requires significant RAM.

### Build Takes Too Long

- Use caching (enabled in the workflow)
- Build only for required architectures
- Use a faster CPU

### Docker BuildKit Issues

Ensure BuildKit is enabled:
```bash
export DOCKER_BUILDKIT=1
```

Or configure it in Docker daemon:
```json
{
  "features": {
    "buildkit": true
  }
}
```

### Kernel Modules Not Loading

Ensure the kernel modules are signed with the same key used to sign the kernel. Talos uses an ephemeral signing key during the build.

## Advanced Topics

### Multi-Architecture Builds

To build for both amd64 and arm64:

```bash
make kernel \
  REGISTRY=ghcr.io/yourname \
  PUSH=true \
  PLATFORM=linux/amd64,linux/arm64
```

### Additional Kernel Configuration Changes

Edit the kernel config files in `pkgs/kernel/build/config-*` to make additional changes. For example:

```bash
cd pkgs/
make kernel-menuconfig  # Interactive configuration
make kernel-olddefconfig  # Update config
```

### System Extensions

Talos supports system extensions for adding additional functionality. These are separate from kernel customizations but can be combined.

See: https://docs.siderolabs.com/talos/latest/build-and-extend-talos/custom-images-and-development/system-extensions/

## References

- [Talos Linux Documentation](https://www.talos.dev/latest/)
- [Customizing the Kernel](https://docs.siderolabs.com/talos/latest/build-and-extend-talos/custom-images-and-development/customizing-the-kernel/)
- [Building Custom Images](https://docs.siderolabs.com/talos/latest/build-and-extend-talos/custom-images-and-development/building-images/)
- [siderolabs/pkgs Repository](https://github.com/siderolabs/pkgs)
- [siderolabs/talos Repository](https://github.com/siderolabs/talos)
