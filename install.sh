#!/usr/bin/env bash

set -euo pipefail

readonly DISK=/dev/nvme0n1
readonly HOSTNAME=mcflurry
readonly USERNAME=ziggoon
readonly PASSWORD=ziggoon

read -srp "[?] Enter LUKS password: " LUKS_PASSWORD
echo
read -srp "[?] Confirm LUKS password: " LUKS_PASSWORD_CONFIRM
echo

if [[ "$LUKS_PASSWORD" != "$LUKS_PASSWORD_CONFIRM" ]]; then
	echo "[!] passwords do not match"
	exit 1
fi

readonly LUKS_PASSWORD

readonly -a PKGS=(
	# base system
	base
	linux
	linux-firmware
	base-devel
	sudo
	man-db
	man-pages

	# boot & disk
	efibootmgr
	btrfs-progs
	cryptsetup

	# networking
	iwd
	bind
	inetutils

	# bluetooth
	bluez
	bluez-utils
	blueman

	# shell & tools
	neovim
	git
	wget
	curl
	tmux
	eza
	jq
	bc
	unzip

	# wayland & hyprland
	hyprland
	wayland
	xdg-desktop-portal-hyprland
	xdg-utils
	qt5-wayland
	qt6-wayland
	uwsm
	waybar
	wofi
	swaybg
	swaylock
	swayidle
	wl-clipboard
	hyprpaper
	polkit-gnome

	# audio
	pipewire
	pipewire-pulse
	wireplumber

	# apps
	ghostty
	nautilus
	brightnessctl

	# fonts & media
	ttf-jetbrains-mono
	libcamera
)

if [[ "$DISK" == *nvme* ]]; then
	PART_PREFIX="${DISK}p"
else
	PART_PREFIX="${DISK}"
fi

readonly PART_PREFIX
readonly PART_EFI="${PART_PREFIX}1"
readonly PART_LUKS="${PART_PREFIX}2"
readonly CRYPT_NAME="cryptroot"
readonly CRYPT_DEVICE="/dev/mapper/${CRYPT_NAME}"
readonly MNT="/mnt"
readonly BTRFS_MOUNT_OPTS="defaults,noatime,compress=zstd:1,space_cache=v2,discard=async"

readonly -a SUBVOLUMES=(
	"@"
	"@home"
	"@snapshots"
	"@var_log"
	"@var_cache"
)

declare -A SUBVOL_MOUNT=(
	[@]="$MNT"
	[@home]="$MNT/home"
	[@snapshots]="$MNT/.snapshots"
	[@var_log]="$MNT/var/log"
	[@var_cache]="$MNT/var/cache"
)

if [[ $EUID -ne 0 ]]; then
	echo "[!] must run as root"
	exit 1
fi

for script in disk chroot dotfiles; do
	if [[ ! -f "scripts/${script}.sh" ]]; then
		echo "[!] missing scripts/${script}.sh"
		exit 1
	fi
	source "scripts/${script}.sh"
done

partition
encrypt
create_fs
create_subvolumes
mount_subvolumes

pacstrap -K "$MNT" "${PKGS[@]}"
genfstab -U "$MNT" >> "$MNT/etc/fstab"

chroot_config
link_dotfiles

umount -R "$MNT"
reboot
