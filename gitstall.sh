#! /usr/bin/env bash
# Author: Sotirios Roussis - xtonousou

declare -r name="gitstall"
declare -r version="v0.1.0"
declare -r etc="/etc/${name}"
declare -r conf="${etc}/${name}.conf"
declare -r cdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

declare -r crst=$'\e[0m'
declare -r cred=$'\e[91m'
declare -r cgrn=$'\e[92m'

function log() {
	echo -e "${cgrn}${name}${crst}: ${1}"
	return 0
}

function install_gitstall() {
	if [ "${EUID}" -ne 0 ]; then
		log "${cred}Please run as root${crst}"
		exit 1
	fi

	if [ ! -d "${etc}" ]; then
		mkdir -pv "${etc}"
		touch "${conf}"
	fi

	cat <<- EOF > "${conf}"
		# Where the git repo will live
		export GITSTALL_DOWNLOAD_DIR="/opt"

		# Where the wrapper script will live
		# Must be in \$PATH env
		export GITSTALL_INSTALLATION_DIR="/usr/local/bin"
	EOF

	chmod -v a+r "${conf}"
	return 0
}

function check_gitstall() {
	if [ ! -f "${conf}" ]; then
		log "It seems that you run ${name} for the first time."
		log "Install required configuration files?"
		log "Press [ENTER] to install or [CTRL+C] to exit "
		read

		install_gitstall
	fi

	return 0
}

function main() {
	check_gitstall

	return 0
}

main ${@}

