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

function _help() {
	echo -e "${name}
	Usage:
		${name} ${cgrn}<URL>${crst}

	Options:
		-h, --help 		Shows this helping message
		-i, --install 	Installs predefined configuration for the program itself"

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

function check_dependencies() {
	if ! hash git 2>/dev/null; then
		log "${cred}'git' is not installed${crst}"
		exit 2
	fi

	return 0
}

function post_conf_check() {
	if [ ! -d "${GITSTALL_DOWNLOAD_DIR}" ]; then
		mkdir -pv "${GITSTALL_DOWNLOAD_DIR}"
	fi

	if [ ! -d "${GITSTALL_INSTALLATION_DIR}" ]; then
		mkdir -pv "${GITSTALL_INSTALLATION_DIR}"
	fi

	return 0
}

function bootstrap() {
	declare -r cname=$(awk -F'/' '{print $NF}' <<< "${1}" | awk -F'.' '{print $1}')
	declare -r opath="${GITSTALL_DOWNLOAD_DIR}/${cname}"
	declare -r wrapper="${GITSTALL_INSTALLATION_DIR}/${cname}"

	# clone the repo
	git clone --depth 1 "${1}" "${opath}"

	# guess the correct/main file
	declare mfile=$(find "${opath}/${cname}"* -maxdepth 0 -type f | grep -Evi "\.png|\.jp|\.*ml|\.md|\.txt" | head -n 1 \
						|| find "${opath}/main"* -maxdepth 0 -type f | grep -Evi "\.png|\.jp|\.*ml|\.md|\.txt" | head -n 1 \
						|| find "${opath}/init"* -maxdepth 0 -type f | grep -Evi "\.png|\.jp|\.*ml|\.md|\.txt" | head -n 1)

	# guess the type of file
	declare -r magic=$(file --brief --mime-type "${mfile}")

	# determine runner
	declare runner
	case "${magic}" in
		"text/x-script.python")
			runner="python3 python"
			;;
		"text/x-shellscript")
			runner="bash sh fish zsh csh"
			;;
		"application/x-pie-executable")
			runner=0
			;;
		"text/javascript")
			runner="node nodejs node-js"
			;;
		"text/x-perl")
			runner="perl"
			;;
		"text/x-php")
			runner="php"
			;;
		"text/x-lua")
			runner="lua"
			;;
		"text/plain")
			runner="vi"
			;;
		"text/xml")
			runner="vi"
			;;
		"text/html")
			runner="vi"
			;;
		"text/x-c++")
			runner="vi"
			;;
		"application/json")
			runner="vi"
			;;
		*)
			runner="file"
			;;
	esac

	declare inspected=0
	for r in ${runner}; do
		if hash "${r}" &>/dev/null; then
			runner="${r}"
			inspected=1
			break
		fi
	done

	if [ "${inspected}" -eq 0 ]; then
		runner=$(awk '{print $1}' <<< "${runner}")
	fi

	# construct wrapper script
	cat <<- EOF > "${wrapper}"
		#!/bin/sh
		${runner} ${mfile} \${@}
	EOF

	chmod -v a+x "${wrapper}"

	return 0
}

function main() {
	if [ -z "${1}" ]; then
		log "${cred}You must specify a repository URL in HTTP or GIT format${crst}"
		exit 3
	fi

	case "${1}" in
		-h|--help)
			_help
			return 0
			;;
		-i|--install)
			install_gitstall
			return 0
			;;
	esac

	check_gitstall
	check_dependencies

	source "${conf}"
	post_conf_check

	bootstrap "${1}"

	return 0
}

main ${@}

