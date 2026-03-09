#!/usr/bin/env bash

install_libvirt() {
	readonly -a LIBVIRT_PKGS=(
		libvirt
		dnsmasq
		qemu-full
		qemu-img
		virt-install
		virt-manager
		virt-viewer
		edk2-ovmf
		swtpm
		guestfs-tools
		libosinfo
	)

	pacman -Sy --noconfirm "${LIBVIRT_PKGS[@]}"

	systemctl enable libvirtd --now

	usermod -aG libvirt $USERNAME

	virt-host-validate qemu

	virsh net-autostart default
}
