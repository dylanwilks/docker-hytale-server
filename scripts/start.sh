#!/bin/bash

source "$(dirname "$0")/utils.sh"

: "${ADDRESS:=0.0.0.0:5520}"
: "${OWNER_UUID:=}"
: "${OWNER_NAME:=}"
: "${ALLOW_OP:=false}"
: "${BOOT_COMMAND:=}"
: "${AUTH_MODE:=authenticated}"
: "${DISABLE_SENTRY:=false}"
: "${ENABLE_BACKUPS:=true}"
: "${BACKUP_DIR:=/backups}"
: "${BACKUP_FREQUENCY:=30}"
: "${BACKUP_MAX_COUNT:=5}"
: "${ACCEPT_EARLY_PLUGINS:=false}"
: "${VALIDATE_ASSETS:=false}"
: "${VALIDATE_WORLD_GEN:=false}"
: "${VALIDATE_PREFABS:=}"
export HYTALE_SERVER_SESSION_TOKEN="${SESSION_TOKEN:-}"
export HYTALE_SERVER_IDENTITY_TOKEN="${IDENTITY_TOKEN:-}"

SERVER_ARGS=()
SERVER_ARGS+=(--bind ${ADDRESS})
SERVER_ARGS+=(--assets Assets.zip)
SERVER_ARGS+=(--auth-mode ${AUTH_MODE})

if [ ! -f auth.enc ] && ([ -z "${SESSION_TOKEN}" ] || [ -z "${IDENTITY_TOKEN}" ]); then
	SERVER_ARGS+=(--boot-command "auth persistence Encrypted","auth login device")
fi

if [ -n "${BOOT_COMMAND}" ]; then
	SERVER_ARGS+=(--boot-command ${BOOT_COMMAND})
fi

if is_true "${ALLOW_OP}"; then
	SERVER_ARGS+=(--allow-op)
fi

if is_true "${ENABLE_BACKUPS}"; then
	SERVER_ARGS+=(--backup \
--backup-frequency ${BACKUP_FREQUENCY} \
--backup-max-count ${BACKUP_MAX_COUNT} \
--backup-dir ${BACKUP_DIR})
fi

if [ -n "${OWNER_UUID}" ]; then
	SERVER_ARGS+=(--owner-uuid ${OWNER_UUID})
fi

if [ -n "${OWNER_NAME}" ]; then
	SERVER_ARGS+=(--owner-name ${OWNER_NAME})
fi

if is_true "${DISABLE_SENTRY}"; then
	SERVER_ARGS+=(--disable-sentry)
fi

if is_true "${ACCEPT_EARLY_PLUGINS}"; then
	SERVER_ARGS+=(--accept-early-plugins)
fi

if is_true "${VALIDATE_ASSETS}"; then
	SERVER_ARGS+=(--validate-assets)
fi

if is_true "${VALIDATE_WORLD_GEN}"; then
	SERVER_ARGS+=(--validate-world-gen)
fi

if [ -n "${VALIDATE_PREFABS}" ]; then
	SERVER_ARGS+=(--validate-prefabs ${VALIDATE_PREFABS})
fi

log "Running HytaleServer.jar..."

JVM_ARGS="$(replace_characters '\n,' ' ' "${JVM_ARGS}")"
exec java ${JVM_ARGS} -jar Server/HytaleServer.jar "${SERVER_ARGS[@]}"
