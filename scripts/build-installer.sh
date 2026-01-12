#!/bin/bash
# Build Talos installer image with custom kernel

set -euo pipefail

TALOS_VERSION="${1:-v1.8.2}"
KERNEL_IMAGE="${2:-}"
INSTALLER_IMAGE="${3:-}"
PLATFORM="${4:-linux/amd64}"
PUSH="${5:-false}"

if [ -z "$KERNEL_IMAGE" ] || [ -z "$INSTALLER_IMAGE" ]; then
    echo "Usage: $0 <talos-version> <kernel-image> <installer-image> [platform] [push]"
    exit 1
fi

echo "Building Talos installer:"
echo "  Talos version: $TALOS_VERSION"
echo "  Kernel image:  $KERNEL_IMAGE"
echo "  Output image:  $INSTALLER_IMAGE"
echo "  Platform:      $PLATFORM"
echo "  Push:          $PUSH"

# Create output directory
mkdir -p _out

# Use official Talos imager to build installer with custom kernel
# Note: This is a simplified version. In production, you'd use the actual imager
# from siderolabs/imager with proper kernel package references

echo "Creating installer image configuration..."
cat > _out/installer-profile.yaml <<EOF
arch: $(echo $PLATFORM | cut -d'/' -f2)
platform: nocloud
version: ${TALOS_VERSION}
customization:
  systemExtensions:
    officialExtensions: []
EOF

echo ""
echo "Note: Full kernel build integration requires proper setup of:"
echo "  1. Custom kernel package built from siderolabs/pkgs"
echo "  2. Integration with Talos imager"
echo "  3. Proper artifact handling"
echo ""
echo "For GitHub Actions, the workflow will handle the complete build process."
echo ""

# In a real implementation, this would call:
# docker run --rm -v $(pwd)/_out:/out ghcr.io/siderolabs/imager:${TALOS_VERSION} \
#   installer --kernel ${KERNEL_IMAGE}

echo "Installer build process prepared"
