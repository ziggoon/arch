#!/usr/bin/env bash

set -euo pipefail

USERNAME=ziggoon

if [[ $EUID -ne 0 ]]; then
	echo "[!] must run as root"
	exit 1
fi

for script in libvirt docker openvpn; do
	if [[ ! -f "scripts/${script}.sh" ]]; then
		echo "[!] missing scripts/${script}.sh"
		exit 1
	fi
	source "scripts/${script}.sh"
done

# install_libvirt
# install_docker
install_openvpn
