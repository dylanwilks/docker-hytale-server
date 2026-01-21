#!/bin/bash

source "$(dirname "$0")/utils.sh"

: "${UNIVERSE_SRC:=/universe}"
: "${WORLDS_SRC:=/universe/worlds}"
: "${OVERWRITE_PLAYERS:=false}"
: "${OVERWRITE_MEMORIES:=false}"
: "${OVERWRITE_WARPS:=false}"
: "${OVERWRITE_WORLDS:=}"
UNIVERSE_DEST=/data/universe
WORLDS_DEST=/data/universe/worlds

log "Copying files in ${UNIVERSE_SRC} to ${UNIVERSE_DEST} (if any exist)."
# Copy/overwrite players
if [ "$(ls -A "${UNIVERSE_SRC}"/players 2> /dev/null)" ]; then
	if [ "${OVERWRITE_PLAYERS}" = true ]; then
		log_warning "OVERWRITE_PLAYERS is true, overwriting ${UNIVERSE_DEST}/players..."
		rm -rf "${UNIVERSE_DEST}"/players
		cp -r "${UNIVERSE_SRC}"/players "${UNIVERSE_DEST}"
	else
		log "${UNIVERSE_SRC}/players already exists. Skipping..."
	fi
else
	log "${UNIVERSE_SRC}/players is not populated. Skipping..."
fi

# Copy/overwrite memories
if [ "$(ls -A "${UNIVERSE_SRC}"/memories.* 2> /dev/null)" ]; then
	if [ "${OVERWRITE_MEMORIES}" = true ]; then
		log_warning "OVERWRITE_MEMORIES is true, overwriting ${UNIVERSE_DEST}/memories.*..."
		rm -rf "${UNIVERSE_DEST}"/memories.*
		cp -r "${UNIVERSE_SRC}"/memories.* "${UNIVERSE_DEST}"
	else
		log "${UNIVERSE_SRC}/memories.* already exists. Skipping..."
	fi
else
	log "${UNIVERSE_SRC}/memories.* does not exist. Skipping..."
fi

# Copy/overwrite warps
if [ "$(ls -A "${UNIVERSE_SRC}"/warps.* 2> /dev/null)" ]; then
	if [ "${OVERWRITE_PLAYERS}" = true ]; then
		log_warning "OVERWRITE_WARPS is true, overwriting ${UNIVERSE_DEST}/warps.*..."
		rm -rf "${UNIVERSE_DEST}"/warps.*
		cp -r "${UNIVERSE_SRC}"/warps.* "${UNIVERSE_DEST}"
	else
		log "${UNIVERSE_SRC}/warps.* already exists. Skipping..."
	fi
else
	log "${UNIVERSE_SRC}/warps.* does not exist. Skipping..."
fi

# Copy all worlds in WORLDS_SRC to WORLDS_DEST. Overwrite if specified
log "Copying worlds in ${WORLDS_SRC} to ${WORLDS_DEST} (if any exist)."
SRC_WORLDS=($(ls -d "${WORLDS_SRC}"/*/ 2> /dev/null | \
	sed 's:/*$::' | \
	awk -F '/' '{print $NF}'))
OVERWRITE=($(replace_characters '\n,' ' ' "${OVERWRITE_WORLDS}"))
for WORLD in "${SRC_WORLDS[@]}"; do
	if [ -d "${WORLDS_DEST}"/"${WORLD}" ]; then
		if $(contains_element "${WORLD}" "${OVERWRITE[@]}"); then
			log_warning "Overwriting world ${WORLDS_DEST}/${WORLD}."
			rm -rf "${WORLDS_DEST}"/"${WORLD}"
			cp -r "${WORLDS_SRC}"/"${WORLD}" "${WORLDS_DEST}"

			continue
		fi

		log "World ${WORLD} already exists. Skipping..."
	else
		cp -r "${WORLDS_SRC}"/"${WORLD}" "${WORLDS_DEST}"
		log "Copied ${WORLDS_SRC}/${WORLD} to ${WORLDS_DEST}."
	fi
done

# Create default world if it does not exist
if [ ! -d "${WORLDS_DEST}"/"${DEFAULT_WORLD}" ]; then
	log_warning "Default world not found in ${WORLDS_DEST}."
	log "Starting server once to generate world files..."

	java -XX:AOTCache=Server/HytaleServer.aot \
		-jar Server/HytaleServer.jar \
		--assets Assets.zip \
		--boot-command stop > /dev/null 2>&1

	log "Successfully created world."
fi


# Edit config.json of each world in WORLDS_DEST via .env files
log "Updating config.json of each world (if any *.env exist)"
ENV_WORLDS=($(ls "${WORLDS_SRC}"/*.env 2> /dev/null | \
	awk -F '/' '{print $NF}' | \
	cut -f 1 -d '.'))
for ENV_WORLD in "${ENV_WORLDS[@]}"; do
	if [ -d "${WORLDS_DEST}/${ENV_WORLD}" ]; then
		CONFIG="$(jq . "${WORLDS_DEST}/${ENV_WORLD}/config.json" 2>&1 /dev/null)"
		if [ "$?" -ne 0 ]; then
			log_warning "${WORLDS_DEST}/${ENV_WORLD}/config.json not found. Skipping..."
			continue
		fi

		ENV="${WORLDS_SRC}/${ENV_WORLD}.env"
		source "${ENV}"

		: "${TICKING:="$(jq -r '.IsTicking' <<< "${CONFIG}")"}"
		: "${BLOCK_TICKING:="$(jq -r '.IsBlockTicking' <<< "${CONFIG}")"}"
		: "${PVP:="$(jq -r '.IsPvpEnabled' <<< "${CONFIG}")"}"
		: "${FALL_DAMAGE:="$(jq -r '.IsFallDamageEnabled' <<< "${CONFIG}")"}"
		: "${GAME_TIME_PAUSED:="$(jq -r '.IsGameTimePaused' <<< "${CONFIG}")"}"
		: "${SPAWN_NPCS:="$(jq -r '.IsSpawningNPC' <<< "${CONFIG}")"}"
		: "${SPAWN_MARKERS:="$(jq -r '.IsSpawnMarkersEnabled' <<< "${CONFIG}")"}"
		: "${FROZEN_NPCS:="$(jq -r '.IsAllNPCFrozen' <<< "${CONFIG}")"}"
		: "${COMPASS_UPDATING:="$(jq -r '.IsCompassUpdating' <<< "${CONFIG}")"}"
		: "${SAVING_PLAYERS:="$(jq -r '.IsSavingPlayers' <<< "${CONFIG}")"}"
		: "${SAVING_CHUNKS:="$(jq -r '.IsSavingChunks' <<< "${CONFIG}")"}"
		: "${SAVE_NEW_CHUNKS:="$(jq -r '.SaveNewChunks' <<< "${CONFIG}")"}"
		: "${UNLOADING_CHUNKS:="$(jq -r '.IsUnloadingChunks' <<< "${CONFIG}")"}"
		: "${OBJECTIVE_MARKERS:="$(jq -r '.IsObjectiveMarkersEnabled' <<< "${CONFIG}")"}"
		: "${DELETE_ON_REMOVE:="$(jq -r '.DeleteOnRemove' <<< "${CONFIG}")"}"

		TMP="$(mktemp)"
		jq ".IsTicking = ${TICKING} | \
			.IsBlockTicking = ${BLOCK_TICKING} | \
			.IsPvpEnabled = ${PVP} | \
			.IsFallDamageEnabled = ${FALL_DAMAGE} | \
			.IsGameTimePaused = ${GAME_TIME_PAUSED} | \
			.IsSpawningNPC = ${SPAWN_NPCS} | \
			.IsSpawnMarkersEnabled = ${SPAWN_MARKERS} | \
			.IsAllNPCFrozen = ${FROZEN_NPCS} | \
			.IsCompassUpdating = ${COMPASS_UPDATING} | \
			.IsSavingPlayers = ${SAVING_PLAYERS} | \
			.IsSavingChunks = ${SAVING_CHUNKS} | \
			.SaveNewChunks = ${SAVE_NEW_CHUNKS} | \
			.IsUnloadingChunks = ${UNLOADING_CHUNKS} | \
			.IsObjectiveMarkersEnabled = ${OBJECTIVE_MARKERS} | \
			.DeleteOnRemove = ${DELETE_ON_REMOVE}" \
			<<< "${CONFIG}" > "${TMP}"
		mv "${TMP}" "${WORLDS_DEST}/${ENV_WORLD}/config.json"

		log "Updated ${WORLDS_DEST}/${ENV_WORLD}/config.json."
	fi
done

exec "$(dirname "$0")/setup_mods.sh"
