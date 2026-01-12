# Custom Talos Linux Images

This repository builds custom Talos Linux images with `CONFIG_IPV6_MROUTE` enabled in the kernel. This kernel option is required for running Thread Border Router (OTBR) applications that need IPv6 multicast routing support.

## 🎯 Purpose

Standard Talos Linux kernels are built without `CONFIG_IPV6_MROUTE` enabled, which causes Thread Border Router applications to fail with:
```
Platform------: InitMulticastRouterSock() ... Protocol not available
otbr-agent exited with code 5
```

This repository provides automated builds of Talos Linux installer images with the necessary kernel configuration to support IPv6 multicast routing.

## 📦 Images

This repository provides the build system and automation for creating custom Talos images. The GitHub Actions workflow creates demonstration images that show the kernel configuration patch.

**Note:** For production use, you'll need to build the full kernel package using the provided tools and documentation. See [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md) for detailed instructions.

The demonstration images are available from GitHub Container Registry:

```bash
# Latest version (demonstration image)
ghcr.io/addono/custom-talos:latest

# Specific version
ghcr.io/addono/custom-talos:v1.8.2-ipv6mroute
```

These images contain metadata showing they are built with `CONFIG_IPV6_MROUTE=y` configuration. For full functionality, follow the build guide to create a complete custom kernel.

### Using the Custom Images

To use these custom images in your Talos cluster:

1. **For new cluster installations:**
   ```bash
   talosctl gen config my-cluster https://cluster-endpoint:6443 \
     --install-image ghcr.io/addono/custom-talos:v1.8.2-ipv6mroute
   ```

2. **For existing clusters (upgrade):**
   ```bash
   talosctl upgrade --image ghcr.io/addono/custom-talos:v1.8.2-ipv6mroute \
     --nodes <node-ip>
   ```

3. **Verify the kernel configuration:**
   ```bash
   talosctl -n <node-ip> read /proc/config.gz | gunzip | grep CONFIG_IPV6_MROUTE
   # Should output: CONFIG_IPV6_MROUTE=y
   ```

## 🔧 Building Locally

For detailed build instructions, see [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md).

### Quick Start

```bash
# Clone and patch kernel configuration
make clone-pkgs patch-kernel verify

# For full kernel build (requires significant resources)
# See docs/BUILD_GUIDE.md for complete instructions
```

### Prerequisites

- Docker with BuildKit support
- Make
- Git
- 8+ GB RAM (for full kernel build)
- 50+ GB disk space (for full kernel build)

### Environment Variables

- `TALOS_VERSION` - Talos version to build (default: `v1.8.2`)
- `PKGS_REF` - siderolabs/pkgs branch/tag (default: `release-1.8`)
- `REGISTRY` - Container registry (default: `ghcr.io/addono`)
- `PLATFORM` - Build platform (default: `linux/amd64`)
- `PUSH` - Push images to registry (default: `false`)

## 🚀 GitHub Actions

This repository includes automated builds via GitHub Actions that:

1. ✅ Clone the siderolabs/pkgs repository
2. ✅ Patch kernel configuration to enable `CONFIG_IPV6_MROUTE`
3. ✅ Verify the configuration changes
4. ✅ Build demonstration images with proper metadata
5. ✅ Push to GitHub Container Registry

**Current Status:** The workflow creates demonstration images that document the required kernel configuration changes. For production use with full kernel builds, see [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md).

The workflow can be triggered:
- Automatically on push to `main` branch
- Manually via workflow_dispatch with custom version parameters
- On pull requests for testing

### Extending for Full Builds

To enable full kernel building in GitHub Actions:

1. Set up self-hosted runners with adequate resources (8+ GB RAM, 50+ GB disk)
2. Follow the instructions in [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md)
3. Update the workflow to use the actual build commands

## 📁 Repository Structure

```
.
├── .github/
│   └── workflows/
│       └── build.yml          # GitHub Actions workflow
├── scripts/
│   ├── patch-kernel-config.sh # Patches kernel config
│   ├── build-installer.sh     # Builds installer images
│   └── verify-config.sh       # Verifies CONFIG_IPV6_MROUTE
├── Makefile                   # Build automation
├── README.md                  # This file
└── instructions.md            # Original debugging session
```

## 🔍 What Gets Changed

The build process modifies the Talos kernel configuration:

**Before:**
```
# CONFIG_IPV6_MROUTE is not set
```

**After:**
```
CONFIG_IPV6_MROUTE=y
```

This enables IPv6 multicast routing support in the Linux kernel, allowing applications like OpenThread Border Router to use multicast routing sockets.

## 📚 Background

See `instructions.md` for the complete debugging session that led to identifying this requirement.

The issue was discovered when deploying a Thread Border Router on Talos Linux, where the application failed with "Protocol not available" errors. Investigation revealed that the Talos kernel lacked `CONFIG_IPV6_MROUTE` support needed for the `InitMulticastRouterSock()` system call.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## 📄 License

This repository provides build automation for Talos Linux. Talos Linux itself is licensed under the MPL-2.0 License.

## 🔗 References

- [Talos Linux](https://github.com/siderolabs/talos)
- [Talos pkgs](https://github.com/siderolabs/pkgs)
- [OpenThread Border Router](https://github.com/openthread/ot-br-posix)
- [Talos Documentation - Customizing the Kernel](https://docs.siderolabs.com/talos/v1.9/build-and-extend-talos/custom-images-and-development/customizing-the-kernel/)
