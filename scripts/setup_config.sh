#!/bin/bash

source "$(dirname "$0")/utils.sh"

CONFIG="$(jq . "config.json" 2>&1 /dev/null)"
if [ "$?" -ne 0 ]; then
	log_warning "config.json not found."
	log "Generating config.json using template..."

	export VERSION="${VERSION:-3}"
	export SERVER_NAME="${SERVER_NAME:-"Hytale Server"}"
	export MOTD="${MOTD:-}"
	export PASSWORD="${PASSWORD:-}"
	export MAX_PLAYERS="${MAX_PLAYERS:-100}"
	export MAX_VIEW_RADIUS="${MAX_VIEW_RADIUS:-32}"
	export LOCAL_COMPRESSION="${LOCAL_COMPRESSION:-false}"
	export DEFAULT_WORLD="${DEFAULT_WORLD:-default}"
	export DEFAULT_GAMEMODE="${DEFAULT_GAMEMODE:-Adventure}"

	envsubst < /templates/config_ver_${VERSION}.json.template > "config.json"

	log "Created config.json."
else
	export SERVER_NAME="${SERVER_NAME:-"$(jq -r '.ServerName' <<< "${CONFIG}")"}"
	export MOTD="${MOTD:-"$(jq -r '.MOTD' <<< "${CONFIG}")"}"
	export PASSWORD="${PASSWORD:-"$(jq -r '.Password' <<< "${CONFIG}")"}"
	export MAX_PLAYERS="${MAX_PLAYERS:-"$(jq -r '.MaxPlayers' <<< "${CONFIG}")"}"
	export MAX_VIEW_RADIUS="${MAX_VIEW_RADIUS:-"$(jq -r '.MaxViewRadius' <<< "${CONFIG}")"}"
	export LOCAL_COMPRESSION="${LOCAL_COMPRESSION:-"$(jq -r '.LocalCompressionEnabled' <<< "${CONFIG}")"}"
	export DEFAULT_WORLD="${DEFAULT_WORLD:-"$(jq -r '.Defaults.World' <<< "${CONFIG}")"}"
	export DEFAULT_GAMEMODE="${DEFAULT_GAMEMODE:-"$(jq -r '.Defaults.GameMode' <<< "${CONFIG}")"}"

	TMP="$(mktemp)"
	jq ".ServerName = \"${SERVER_NAME}\" | \
		.MOTD = \"${MOTD}\" | \
		.Password = \"${PASSWORD}\" | \
		.MaxPlayers = ${MAX_PLAYERS} | \
		.MaxViewRadius = ${MAX_VIEW_RADIUS} | \
		.Defaults.World = \"${DEFAULT_WORLD}\" | \
		.Defaults.GameMode = \"${DEFAULT_GAMEMODE}\"" \
		<<< "${CONFIG}" > "${TMP}"
	mv "${TMP}" config.json

	log "Updated config.json."
fi

CONFIG="$(jq . "config.json")"

exec "$(dirname "$0")/setup_universe.sh"
