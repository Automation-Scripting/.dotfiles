#!/usr/bin/env bash

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias c='clear'

bash() {
	local cwd="$PWD"
	# shellcheck disable=SC1090
	source ~/.bashrc
	cd "$cwd" || return
}
