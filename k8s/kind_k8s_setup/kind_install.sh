#!/bin/bash

# Detect architecture
ARCH=$(uname -m)

if [[ "$ARCH" == "x86_64" ]]; then
    echo "Detected Intel Mac (x86_64)"
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-darwin-amd64
elif [[ "$ARCH" == "arm64" ]]; then
    echo "Detected Apple Silicon (M1/M2/M3)"
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.30.0/kind-darwin-arm64
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

echo "kind installation completed!"
kind --version
