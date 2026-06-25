#!/bin/bash
set -euo pipefail

DOCKER_KEYRING="/etc/apt/keyrings/docker.gpg"
DOCKER_GPG_URL="https://download.docker.com/linux/ubuntu/gpg"
DOCKER_SOURCE="/etc/apt/sources.list.d/docker.list"
DOCKER_INSTALL_PACKAGES=(
  docker-ce
  docker-ce-cli
  docker-ce-rootless-extras
  containerd.io
  docker-buildx-plugin
  docker-compose-plugin
)

download_docker_gpg() {
  local KEY_ASC
  local KEY_GPG
  KEY_ASC="$(mktemp /tmp/docker-gpg.XXXXXX)"
  KEY_GPG="$(mktemp /tmp/docker-keyring.XXXXXX)"

  rm -f "$KEY_ASC" "$KEY_GPG"
  curl -fsSL "$DOCKER_GPG_URL" -o "$KEY_ASC"

  if [ ! -s "$KEY_ASC" ]; then
    echo "Failed to download Docker GPG key from $DOCKER_GPG_URL" >&2
    echo "Check network access, proxy settings, or try again later." >&2
    exit 1
  fi

  gpg --dearmor -o "$KEY_GPG" "$KEY_ASC"
  sudo install -m 0644 "$KEY_GPG" "$DOCKER_KEYRING"
  rm -f "$KEY_ASC" "$KEY_GPG"
}

install_docker() {
  local TARGET_USER

  sudo apt update
  sudo apt install -y ca-certificates curl gnupg lsb-release

  sudo install -m 0755 -d /etc/apt/keyrings
  download_docker_gpg

  ARCH="$(dpkg --print-architecture)"
  CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
  echo "deb [arch=$ARCH signed-by=$DOCKER_KEYRING] https://download.docker.com/linux/ubuntu $CODENAME stable" \
    | sudo tee "$DOCKER_SOURCE" > /dev/null

  sudo apt update
  sudo apt install -y "${DOCKER_INSTALL_PACKAGES[@]}"

  sudo systemctl enable --now docker

  TARGET_USER="${SUDO_USER:-$USER}"
  sudo groupadd -f docker
  sudo usermod -aG docker "$TARGET_USER"

  docker --version
  echo
  echo "User '$TARGET_USER' has been added to the docker group."
  echo "Run 'newgrp docker' or log out and back in before using docker without sudo."
}

install_docker
