#!/bin/bash
# Patch Talos kernel configuration to enable CONFIG_IPV6_MROUTE

set -euo pipefail

PKGS_DIR="${1:-_out/pkgs}"

if [ ! -d "$PKGS_DIR" ]; then
    echo "Error: pkgs directory not found at $PKGS_DIR"
    exit 1
fi

echo "Patching kernel configuration in $PKGS_DIR..."

# Find all kernel config files
CONFIG_FILES=$(find "$PKGS_DIR/kernel/build" -name "config-*" -type f 2>/dev/null || true)

if [ -z "$CONFIG_FILES" ]; then
    echo "Error: No kernel config files found"
    exit 1
fi

PATCHED=0

for config_file in $CONFIG_FILES; do
    echo "Processing $(basename $config_file)..."
    
    # Check current state
    if grep -q "^CONFIG_IPV6_MROUTE=y" "$config_file"; then
        echo "  ✓ CONFIG_IPV6_MROUTE already enabled"
        PATCHED=$((PATCHED + 1))
        continue
    fi
    
    # Enable CONFIG_IPV6_MROUTE
    if grep -q "^# CONFIG_IPV6_MROUTE is not set" "$config_file"; then
        sed -i 's/^# CONFIG_IPV6_MROUTE is not set/CONFIG_IPV6_MROUTE=y/' "$config_file"
        echo "  ✓ Enabled CONFIG_IPV6_MROUTE (was disabled)"
    elif grep -q "^CONFIG_IPV6_MROUTE=" "$config_file"; then
        sed -i 's/^CONFIG_IPV6_MROUTE=.*/CONFIG_IPV6_MROUTE=y/' "$config_file"
        echo "  ✓ Changed CONFIG_IPV6_MROUTE to y"
    else
        # Add the config if not present
        echo "CONFIG_IPV6_MROUTE=y" >> "$config_file"
        echo "  ✓ Added CONFIG_IPV6_MROUTE=y"
    fi
    
    PATCHED=$((PATCHED + 1))
done

echo ""
echo "Successfully patched $PATCHED kernel configuration file(s)"
echo "CONFIG_IPV6_MROUTE is now enabled"
