#!/bin/bash -x

set -e

if [ "${1-}" = "--prepare" ]; then
    exit 0
fi

echo "linux" | passwd root --stdin

systemctl enable NetworkManager.service

echo "Hello from Combustion!"
