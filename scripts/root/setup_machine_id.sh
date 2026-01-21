#!/bin/bash

source "$(dirname "$0")/../utils.sh"

MACHINE_ID_DIR=./.machine-id
mkdir -p "${MACHINE_ID_DIR}"

if [ ! -f "${MACHINE_ID_DIR}"/uuid ]; then
	log "Creating machine-id..."
	MACHINE_UUID=$(cat /proc/sys/kernel/random/uuid)
	MACHINE_UUID_NO_DASH=$(echo "${MACHINE_UUID}" | tr -d '-')

	echo "${MACHINE_UUID_NO_DASH}" > "${MACHINE_ID_DIR}"/machine-id
	echo "${MACHINE_UUID_NO_DASH}" > "${MACHINE_ID_DIR}"/dbus-machine-id
	echo "${MACHINE_UUID}" > "${MACHINE_ID_DIR}"/product-uuid
	echo "${MACHINE_UUID}" > "${MACHINE_ID_DIR}"/uuid
fi

cp "${MACHINE_ID_DIR}"/machine-id /etc/machine-id
mkdir -p /var/lib/dbus 2> /dev/null
cp "${MACHINE_ID_DIR}"/dbus-machine-id /var/lib/dbus/machine-id
