#!/bin/bash

log() {
	printf "[$(date +'%Y/%m/%d %T')   INFO] ${1}\n"
}

log_warning() {
	printf "[$(date +'%Y/%m/%d %T')   WARN] ${1}\n"
}

log_error() {
	printf "[$(date +'%Y/%m/%d %T') ERRROR] ${1}\n"
}

# Very crude solution; to be changed if necessary
get_version() {
	local words=($@)
	for word in "${words[@]}"; do
		if [[ "${word}" =~ "." ]]; then
			printf "${word}" | sed 's/[()]//g'
			break
		fi
	done
}

is_true() {
	case "${1,,}" in
		true | yes | on | 1) 
			return 0
			;;
		*) 
			return 1
			;;
	esac
}

is_false() {
	case "${1,,}" in
		false | no | off | 0) 
			return 0
			;;
		*) 
			return 1
			;;
	esac
}

replace_characters() {
	local args=("$@")
	local words=""
	for i in $(seq 2 $#); do
		words="${words}${args[${i}]}"
	done

	printf -- "${words}" | tr "$1" "$2"
}

contains_element() {
	for e in "${@:2}"; do
		[[ "${e}" == "${1}" ]] && return 0;
	done

	return 1
}
