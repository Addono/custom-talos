# Example Talos Configuration Using Custom Image

This directory contains example configurations for using custom Talos images with CONFIG_IPV6_MROUTE enabled.

## Quick Start

### 1. Generate Configuration with Custom Installer Image

```bash
talosctl gen config my-cluster https://cluster.example.com:6443 \
  --install-image ghcr.io/addono/custom-talos:v1.8.2-ipv6mroute \
  --output-dir ./talos-config/
```

This creates the following files:
- `controlplane.yaml` - Control plane node configuration
- `worker.yaml` - Worker node configuration
- `talosconfig` - Talosctl client configuration

### 2. Deploy to Nodes

```bash
# Apply to control plane
talosctl apply-config --insecure \
  --nodes 192.168.1.10 \
  --file ./talos-config/controlplane.yaml

# Apply to workers
talosctl apply-config --insecure \
  --nodes 192.168.1.11,192.168.1.12 \
  --file ./talos-config/worker.yaml
```

### 3. Verify Installation

```bash
# Wait for the cluster to be ready
talosctl --talosconfig ./talos-config/talosconfig bootstrap --nodes 192.168.1.10

# Check kernel configuration
talosctl --talosconfig ./talos-config/talosconfig \
  -n 192.168.1.10 \
  read /proc/config.gz | gunzip | grep CONFIG_IPV6_MROUTE

# Expected output: CONFIG_IPV6_MROUTE=y
```

## Upgrading Existing Cluster

If you have an existing Talos cluster and want to upgrade to use the custom kernel:

```bash
# Upgrade nodes one at a time
talosctl upgrade \
  --nodes 192.168.1.10 \
  --image ghcr.io/addono/custom-talos:v1.8.2-ipv6mroute \
  --preserve
```

## Configuration Customization

### Thread Border Router Example

For the Thread Border Router use case that motivated this custom image:

```yaml
# thread-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: thread
  namespace: homeassistant
spec:
  replicas: 1
  selector:
    matchLabels:
      app: thread
  template:
    metadata:
      labels:
        app: thread
    spec:
      hostNetwork: true
      containers:
      - name: thread
        image: openthread/otbr:latest
        securityContext:
          privileged: true
          capabilities:
            add:
              - NET_ADMIN
              - NET_RAW
              - SYS_ADMIN
```

After deployment, verify:

```bash
# Check that otbr-agent starts successfully
kubectl logs -n homeassistant deployment/thread

# Should NOT see:
# "Platform------: InitMulticastRouterSock() ... Protocol not available"
# "otbr-agent exited with code 5"
```

## Troubleshooting

### Verify Kernel Configuration

```bash
# Check if CONFIG_IPV6_MROUTE is enabled
talosctl -n <node-ip> read /proc/config.gz | gunzip | grep -E "(CONFIG_IPV6_MROUTE|CONFIG_IPV6)"
```

Expected output should include:
```
CONFIG_IPV6=y
CONFIG_IPV6_MROUTE=y
```

## Additional Resources

- [Talos Configuration Reference](https://www.talos.dev/latest/reference/configuration/)
- [Talosctl Commands](https://www.talos.dev/latest/reference/cli/)
- [OpenThread Border Router](https://openthread.io/guides/border-router)
