#!/usr/bin/env bash

dotfiles() {
	local script_dir
	script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

	# copy dotfiles into the installed system
	cp -r "${script_dir}/dotfiles" "${MNT}/tmp/dotfiles"

	arch-chroot "$MNT" /bin/bash <<-DOTEOF
	mkdir -p /home/${USERNAME}/.config

	for dir in /tmp/dotfiles/*/; do
	    name="\$(basename "\$dir")"
	    [ "\$name" = "config" ] && continue
	    cp -r "\$dir" "/home/${USERNAME}/.config/\$name"
	done

	cp /tmp/dotfiles/config/bashrc /home/${USERNAME}/.bashrc

	chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
	rm -rf /tmp/dotfiles
	DOTEOF
}
