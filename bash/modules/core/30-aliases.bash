#!/usr/bin/env bash

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias c='clear'

reloadsh() {
	local cwd="$PWD"
	# shellcheck disable=SC1090
	source ~/.bashrc
	cd "$cwd" || return
}
