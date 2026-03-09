#!/usr/bin/env bash

install_openvpn() {
	pacman -Sy --noconfirm openvpn

	curl https://raw.githubusercontent.com/jonathanio/update-systemd-resolved/refs/heads/master/update-systemd-resolved -o /etc/openvpn/update-systemd-resolved

	chmod +x /etc/openvpn/update-systemd-resolved
}
