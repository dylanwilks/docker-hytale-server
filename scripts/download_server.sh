#!/bin/bash

source "$(dirname "$0")/utils.sh"

: "${UPDATE_SERVER:=true}"
: "${FORCE_DOWNLOAD:=false}"
: "${SKIP_UPDATE_CHECK:=false}"
: "${USE_PRERELEASE:=false}"
: "${UPDATE_AOT:=true}"
DOWNLOADER_NAME=hytale-downloader-linux-amd64
VERSION_FILE=.version

get_downloader() {
	log "Downloading hytale-downloader.zip..."
	wget https://downloader.hytale.com/hytale-downloader.zip -O hytale-downloader.zip
	if [ "$?" -ne 0 ]; then
		log_error "Failed to download zip file hytale-downloader.zip."
		exit 1
	fi

	unzip -o hytale-downloader.zip ${DOWNLOADER_NAME}
	chmod +x ${DOWNLOADER_NAME}
	rm hytale-downloader.zip
	if [ ! -f ./"${DOWNLOADER_NAME}" ]; then
		log_error "Failed to get ${DOWNLOADER_NAME}."
		exit 1
	else
		log "${DOWNLOADER_NAME} exists."
	fi
}

train_aot() {
	log "Training AOT cache (running server jar with --bare option)..."

	java -XX:AOTCacheOutput=/data/Server/HytaleServer.aot \
		-jar /data/Server/HytaleServer.jar \
		--assets Assets.zip \
		--boot-command stop > /dev/null 2>&1

	log "Created HytaleServer.aot."
}

download_server() {
	if [ ! -f ./.hytale-downloader-credentials.json ]; then
		log_warning "Credentials not found. Authentication required to download files."
	fi

	printf "\n"
	./"${DOWNLOADER_NAME}" "${1}"
	local version="$(./${DOWNLOADER_NAME} ${1} --print-version)"
	unzip -o "${version}.zip"
	rm "${version}.zip"
	log "Successfully downloaded server files."
	echo "${version}" > "${VERSION_FILE}"

	if is_true "${UPDATE_AOT}"; then
		train_aot
	fi
}

# Check for hytale-downloader-linux-amd64. Download if it does not exist
if [ ! -f ./"${DOWNLOADER_NAME}" ]; then
	log "${DOWNLOADER_NAME} not found."
	get_downloader
fi

# Download game files
ARGS=""
if is_true "${SKIP_UPDATE_CHECK}"; then
	log_warning "Skipping update check, ${DOWNLOADER_NAME} version will not be checked."
	ARGS="${ARGS} --skip-update-check"
else
	CURRENT_VERSION="$(./${DOWNLOADER_NAME} --version)"
	LATEST_VERSION="$(get_version "$(./${DOWNLOADER_NAME} --check-update)")"
	if [ "${CURRENT_VERSION}" != "${LATEST_VERSION}" ]; then
		log_warning "Outdated downloader, most recent downloader version is \
${RECENT_VERSION} (current: ${CURRENT_VERSION})."
		get_downloader
	fi
fi

if is_true "${USE_PRERELEASE}"; then
	log_warning "${DOWNLOADER_NAME} set to download from pre-release channel."
	ARGS="${ARGS} --patchline pre-release"
fi

if [ ! -f ./Server/HytaleServer.jar ] || [ ! -f ./Assets.zip ]; then
	log_warning "Missing server files. Perhaps first time setup?"
	download_server "${ARGS}"
elif is_true "${FORCE_DOWNLOAD}"; then
	log_warning "FORCE_DOWNLOAD is true. Downloading files regardless of version."
	download_server "${ARGS}"
elif is_true "${UPDATE_SERVER}"; then
	if [ -f "${VERSION_FILE}" ]; then
		CURRENT_GAME_VERSION=$(cat "${VERSION_FILE}")
	fi

	LATEST_GAME_VERSION="$(./${DOWNLOADER_NAME} ${ARGS} --print-version)"
	if [ -z "${CURRENT_GAME_VERSION}" ]; then
		log_warning "Cannot identity current version (missing .version)."
		log_warning "Set to download files..."
		download_server "${ARGS}"
	elif [ "${CURRENT_GAME_VERSION}" = "${LATEST_GAME_VERSION}" ]; then
		log "Server is up-to-date (current: ${CURRENT_GAME_VERSION}). Skipping download."
	else
		log_warning "Server is out-of-date (current: ${CURRENT_GAME_VERSION}). \
Latest version is ${LATEST_GAME_VERSION}."
		download_server "${ARGS}"
	fi
fi

exec "$(dirname "$0")/setup_config.sh"
