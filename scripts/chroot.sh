#!/usr/bin/env bash

chroot_config() {
	arch-chroot /mnt <<CHROOTEOF
	ln -sf /usr/share/zoneinfo/America/Chicago /etc/localtime
	hwclock --systohc

	sed -i 's/^#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
	locale-gen
	echo "LANG=en_US.UTF-8" > /etc/locale.conf
	echo "KEYMAP=us" > /etc/vconsole.conf

	echo "$HOSTNAME" > /etc/hostname
	cat <<EOF > /etc/hosts
	127.0.0.1   localhost
	::1         localhost
	127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
	EOF

	sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt filesystems fsck)/' /etc/mkinitcpio.conf
	mkinitcpio -P

	bootctl install

	cat <<EOF > /boot/loader/loader.conf
	default arch.conf
	timeout 3
	console-mode max
	editor  no
	EOF

	UUID="$(blkid -s UUID -o value "${PART_LUKS}")"
	cat <<EOF > /boot/loader/entries/arch.conf
	title   $HOSTNAME
	linux   /vmlinuz-linux
	initrd  /initramfs-linux.img
	options cryptdevice=UUID=$UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw
	EOF

	cat <<EOF > /boot/loader/entries/arch-fallback.conf
	title   $HOSTNAME (fallback)
	linux   /vmlinuz-linux
	initrd  /initramfs-linux-fallback.img
	options cryptdevice=UUID=$UUID:cryptroot root=/dev/mapper/cryptroot rootflags=subvol=@ rw
	EOF

	cat <<EOF > /etc/systemd/network/20-wireless.network
	[Match]
	Name=wlan0

	[Network]
	DHCP=yes
	DNS=1.1.1.1
	DNS=8.8.8.8
	EOF

	systemctl enable iwd systemd-networkd systemd-resolved
	ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

	echo "root:$PASSWORD" | chpasswd
	useradd -m -G wheel -s /bin/bash "$USERNAME"
	echo "$USERNAME:$PASSWORD" | chpasswd
	sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

	su $USERNAME
	cd "/home/$USERNAME"
	git clone https://aur.archlinux.org/yay.git
	cd yay
	makepkg -si

	exit
	CHROOTEOF
}
