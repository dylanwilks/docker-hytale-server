#!/bin/bash

source "$(dirname "$0")/utils.sh"

: "${MODS_SRC:=/mods}"
: "${REMOVE_OLD_MODS:=false}"
MODS_DEST=/data/mods

if is_true "${REMOVE_OLD_MODS}"; then
	log_warning "REMOVE_OLD_MODS is true, removing all mods and configs in ${MODS_SRC}."
	rm -rf "${MODS_SRC}/*" > /dev/null 2>&1
fi

if [ -n "$(ls -A "${MODS_SRC}" 2> /dev/null)" ]; then
	log "Copying mods and configs in ${MODS_SRC} to ${MODS_DEST}..."
	mkdir -p "${MODS_DEST}" 2> /dev/null
	cp -r --update "${MODS_SRC}"/* "${MODS_DEST}"
fi

exec "$(dirname "$0")/start.sh"
