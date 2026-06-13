#!/usr/bin/env bash
set -euo pipefail

# Hosted runner images can contain optional Microsoft repositories that
# intermittently reject apt requests. They are unrelated to RipMe's build.
for source in /etc/apt/sources.list.d/*; do
  if [[ -f "$source" ]] && grep -q 'packages.microsoft.com' "$source"; then
    sudo rm -f "$source"
  fi
done

sudo apt-get update
sudo apt-get install -y \
  clang \
  cmake \
  ninja-build \
  pkg-config \
  libgtk-3-dev \
  liblzma-dev \
  libayatana-appindicator3-dev \
  libnotify-dev \
  libgstreamer1.0-dev \
  libgstreamer-plugins-base1.0-dev
