#!/usr/bin/env bash

readonly -a DOCKER_PKGS=(
	docker
	docker-compose
	docker-buildx
)

install_docker() {
	pacman -Sy --noconfirm "${DOCKER_PKGS[@]}"

	usermod -aG docker $USERNAME

	# start docker on first 'docker' call rather than on boot
	systemctl enable --now docker.socket
}
