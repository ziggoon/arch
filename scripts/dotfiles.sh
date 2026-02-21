#!/usr/bin/env bash

link_dotfiles() {
	arch-chroot "$MNT" runuser -u "$USERNAME" -- bash -c '
		cd /home/'"$USERNAME"'
		git clone https://github.com/ziggoon/dotfiles.git
		mkdir -p .config
		for dir in dotfiles/*/; do
			name="$(basename "$dir")"
			[ "$name" = "config" ] && continue
			ln -sfn "$(realpath "$dir")" ".config/$name"
		done
		ln -sf "$(realpath dotfiles/config/bashrc)" .bashrc
	'
}
