#!/usr/bin/env bash

USER_HOME="/home/$USERNAME"

for dir in dotfiles/*/; do
    name="$(basename "$dir")"
    if [[ "$name" == "config" ]]; then
        continue
    fi
    ln -sfn "$(realpath "$dir")" "${USER_HOME}/.config/${name}"
done

ln -sf "$(realpath dotfiles/config/bashrc)" "${USER_HOME}/.bashrc"

chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}"
