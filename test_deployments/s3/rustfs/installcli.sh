#!/bin/bash
# https://docs.rustfs.com/de/operations/rc
curl -fLO https://github.com/rustfs/cli/releases/download/v0.1.36/rustfs-cli-linux-amd64-v0.1.36.tar.gz
tar -xzf rustfs-cli-linux-amd64-v0.1.36.tar.gz
sudo install -m 0755 rc /usr/local/bin/rc
