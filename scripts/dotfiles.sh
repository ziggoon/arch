#!/usr/bin/env bash

dotfiles() {
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

	# bashrc lives in home directory, not .config
	ln -sf "$(realpath "${script_dir}/dotfiles/config/bashrc")" "${user_home}/.bashrc"

	chown -R "${USERNAME}:${USERNAME}" "${user_home}"
}
