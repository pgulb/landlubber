#!/usr/bin/env bash

arch=$(dpkg --print-architecture)
echo "detected CPU architecture: $arch"
case $arch in
    "amd64" | "arm64")
    wget "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$arch" -O /usr/bin/yq
    chmod +x /usr/bin/yq
        ;;
    *)
        echo "Unsupported architecture: $(dpkg --print-architecture)"
        exit 1
        ;;
esac
