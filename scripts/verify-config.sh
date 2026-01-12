#!/bin/bash
# Verify that CONFIG_IPV6_MROUTE is enabled in kernel configuration

set -euo pipefail

PKGS_DIR="${1:-_out/pkgs}"

if [ ! -d "$PKGS_DIR" ]; then
    echo "Error: pkgs directory not found at $PKGS_DIR"
    exit 1
fi

echo "Verifying kernel configuration..."

CONFIG_FILES=$(find "$PKGS_DIR/kernel/build" -name "config-*" -type f 2>/dev/null || true)

if [ -z "$CONFIG_FILES" ]; then
    echo "Error: No kernel config files found"
    exit 1
fi

ALL_GOOD=true

for config_file in $CONFIG_FILES; do
    echo ""
    echo "Checking $(basename $config_file):"
    
    if grep -q "^CONFIG_IPV6_MROUTE=y" "$config_file"; then
        echo "  ✓ CONFIG_IPV6_MROUTE=y"
    elif grep -q "^# CONFIG_IPV6_MROUTE is not set" "$config_file"; then
        echo "  ✗ CONFIG_IPV6_MROUTE is NOT set"
        ALL_GOOD=false
    elif grep -q "^CONFIG_IPV6_MROUTE=" "$config_file"; then
        VALUE=$(grep "^CONFIG_IPV6_MROUTE=" "$config_file")
        echo "  ⚠ $VALUE (expected =y)"
        ALL_GOOD=false
    else
        echo "  ✗ CONFIG_IPV6_MROUTE not found"
        ALL_GOOD=false
    fi
done

echo ""

if [ "$ALL_GOOD" = true ]; then
    echo "✓ All configurations are correct"
    exit 0
else
    echo "✗ Some configurations are incorrect"
    exit 1
fi
