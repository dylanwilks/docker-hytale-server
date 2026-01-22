#!/bin/bash

source "$(dirname "$0")/utils.sh"

# Check system ARCH 
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "arm64" ] && [ "$ARCH" != "aarch64" ]; then
	log_error "Hytale servers only support x86_64 and arm64 architecture currently."
	log_error "Current architecture: ${ARCH}"
	exit 1
fi

# Set up machine id
"$(dirname "$0")"/root/setup_machine_id.sh

# Change user and group
if [ "${GID}" != 0 ]; then
	addgroup --gid "${GID}" hytale > /dev/null 2>&1
fi

if [ "${UID}" != 0 ]; then
	adduser --system --shell /bin/false --uid "${UID}" --ingroup hytale --home /data hytale > /dev/null 2>&1
fi

chown -R ${UID}:${GID} /data 2> /dev/null

exec gosu ${UID}:${GID} "$(dirname "$0")/download_server.sh" 
