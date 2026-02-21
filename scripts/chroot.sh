#!/usr/bin/env bash

chroot_config() {
	arch-chroot /mnt <<-CHROOTEOF
	ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
	hwclock --systohc

	sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf
	echo "KEYMAP=us" > /etc/vconsole.conf
	echo "$HOSTNAME" > /etc/hostname

	cat > /etc/hosts <<-HOSTS
	127.0.0.1   localhost
	::1         localhost
	127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
	HOSTS

	sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
	mkinitcpio -P

	bootctl install

	cat > /boot/loader/loader.conf <<-LOADER
	default arch.conf
	timeout 3
	console-mode max
	editor  no
	LOADER

	UUID="\$(blkid -s UUID -o value ${PART_LUKS})"

	cat > /boot/loader/entries/arch.conf <<-ARCHCONF
	title   $HOSTNAME
	linux   /vmlinuz-linux
	initrd  /initramfs-linux.img
	options cryptdevice=UUID=\$UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw
	ARCHCONF

	cat > /boot/loader/entries/arch-fallback.conf <<-ARCHFB
	title   $HOSTNAME (fallback)
	linux   /vmlinuz-linux
	initrd  /initramfs-linux-fallback.img
	options cryptdevice=UUID=\$UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw
	ARCHFB

	cat > /etc/systemd/network/20-wireless.network <<-NETWORK
	[Match]
	Name=wlan0
	[Network]
	DHCP=yes
	DNS=1.1.1.1
	DNS=8.8.8.8
	NETWORK

	systemctl enable iwd systemd-networkd systemd-resolved
	ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

	chpasswd <<< "root:$PASSWORD"
	useradd -m -G wheel -s /bin/bash "$USERNAME"
	chpasswd <<< "$USERNAME:$PASSWORD"
	sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
	
	runuser -u "$USERNAME" -- bash -c '
	    cd /home/$USERNAME
	    git clone https://aur.archlinux.org/yay.git
	    cd yay
	    makepkg -si --noconfirm
	'

	local user_home="/home/${USERNAME}"
	local script_dir
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

	mkdir -p "${user_home}/.config"

	local dir name
	for dir in "${script_dir}"/dotfiles/*/; do
		name="$(basename "$dir")"
		[[ "$name" == "config" ]] && continue
		ln -sfn "$(realpath "$dir")" "${user_home}/.config/${name}"
	done

	ln -sf "$(realpath "${script_dir}/dotfiles/config/bashrc")" "${user_home}/.bashrc"

	chown -R "${USERNAME}:${USERNAME}" "${user_home}"
	CHROOTEOF
}
