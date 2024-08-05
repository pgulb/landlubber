#!/usr/bin/env bash

arch=$(dpkg --print-architecture)
echo "detected CPU architecture: $arch"
case $arch in
    "amd64" | "arm64")
        ver=$(curl -L -s https://dl.k8s.io/release/stable.txt)
        curl -LO "https://dl.k8s.io/release/$ver/bin/linux/$arch/kubectl"
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        ;;
    *)
        echo "Unsupported architecture: $(dpkg --print-architecture)"
        exit 1
        ;;
esac
