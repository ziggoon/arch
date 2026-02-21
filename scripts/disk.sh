#!/usr/bin/env bash

partition() {
	sgdisk --zap-all "$DISK"
	sgdisk --new=1:0:+512M --typecode=1:ef00 --change-name=1:"EFI" "$DISK"
	sgdisk --new=2:0:0 --typecode=2:8309 --change-name=2:"LUKS" "$DISK"
	partprobe "$DISK"
}

encrypt() {
	echo -n "$LUKS_PASSWORD" | cryptsetup luksFormat \
		--key-file=- \
		--type luks2 \
		--cipher aes-xts-plain64 \
		--key-size 512 \
		--hash sha512 \
		--iter-time 5000 \
		--pbkdf argon2id \
		"$PART_LUKS"

	echo -n "$LUKS_PASSWORD" | cryptsetup open \
		--key-file=- \
		"$PART_LUKS" "$CRYPT_NAME"
}

create_fs() {
	mkfs.fat -F32 "$PART_EFI"
	mkfs.btrfs -f -L archroot "$CRYPT_DEVICE"
}

create_subvolumes() {
	mount "$CRYPT_DEVICE" "$MNT"

	local sv
	for sv in "${SUBVOLUMES[@]}"; do
		btrfs subvolume create "${MNT}/${sv}"
	done

	umount "$MNT"
}

mount_subvolumes() {
	mount -o "subvol=@,${BTRFS_MOUNT_OPTS}" "$CRYPT_DEVICE" "$MNT"

	local sv mountpoint
	for sv in "${SUBVOLUMES[@]}"; do
		[[ "$sv" == "@" ]] && continue
		mountpoint="${SUBVOL_MOUNT[$sv]}"
		mkdir -p "$mountpoint"
		mount -o "subvol=${sv},${BTRFS_MOUNT_OPTS}" "$CRYPT_DEVICE" "$mountpoint"
	done

	mkdir -p "${MNT}/boot"
	mount "$PART_EFI" "${MNT}/boot"
}
