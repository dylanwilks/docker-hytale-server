#!/bin/bash

source "scripts/utils.sh"

request_device_code() {
	local request='curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/device/auth" \
		-H "Content-Type: application/x-www-form-urlencoded" \
		-d "client_id=hytale-server" \
		-d "scope=openid offline auth:server"'
	local response="$(eval "${request}")"
	if [ "$?" -ne 0 ]; then
		return "1"
	fi

	printf '%s' "${response}"
}

poll_for_token() {
	local request='curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/token" \
		-H "Content-Type: application/x-www-form-urlencoded" \
		-d "client_id=hytale-server" \
		-d "grant_type=urn:ietf:params:oauth:grant-type:device_code" \
		-d "device_code=${1}"'
	local time=0
	while true; do
		local response="$(eval "${request}")"
		if [ "$?" -ne 0 ]; then
			return "1"
		fi

		local success="$(jq 'has("access_token")' <<< "${response}")"
		if "${success}"; then
			break
		elif [ ${time} -gt ${3} ]; then
			return "2"
		fi

		sleep "$((${2}))"
		time=$((${time} + 5))
	done
	
	printf '%s' "${response}"
}

request_profiles() {
	local request='curl -s -X GET "https://account-data.hytale.com/my-account/get-profiles" \
		-H "Authorization: Bearer ${1}" \
		-H "Content-Type: application/json"'
	local response="$(eval "${request}")"
	if [ "$?" -ne 0 ]; then
		return 1
	fi

	printf '%s' "${response}"
}

create_game_session() {
	local request="curl -s -X POST \"https://sessions.hytale.com/game-session/new\" \
		-H \"Authorization: Bearer ${1}\" \
		-H \"Content-Type: application/json\" \
		-d '{\"uuid\": \"${2}\"}'"
	local response="$(eval "${request}")"
	if [ "$?" -ne 0 ]; then
		return "1"
	fi

	printf '%s' "${response}"
}

refresh_access_token() {
	local request='curl -s -X POST "https://oauth.accounts.hytale.com/oauth2/token" \
		-H "Content-Type: application/x-www-form-urlencoded" \
		-d "client_id=hytale-server" \
		-d "grant_type=refresh_token" \
		-d "refresh_token=${1}"'
	local response="$(eval "${request}")"
	if [ "$?" -ne 0 ]; then
		return "1"
	fi

	printf '%s' "${response}"
}

# Check for refresh token
if [ -f ".refresh_token" ]; then
	log "Requesting for new access token..."
	TOKEN_RESPONSE="$(refresh_access_token $(cat .refresh_token))"
	ERROR="$(jq -r '.error // empty' <<< "${TOKEN_RESPONSE}")"
fi

# Get new refresh token if invalid
if [ ! -f ".refresh_token"  ] || [ -n "${ERROR}" ]; then
	log_warning "Refresh token invalid. Verification will be required for a new one."
	log "Requesting for device code."
	DEVICE_CODE_RESPONSE="$(request_device_code)"
	if [ "${DEVICE_CODE_RESPONSE}" = 1 ]; then
		log_error "Reponse for device code failed."
		exit 1
	fi

	DEVICE_CODE="$(jq -r '.device_code' <<< "${DEVICE_CODE_RESPONSE}")"
	USER_CODE="$(jq -r '.user_code' <<< "${DEVICE_CODE_RESPONSE}")"
	VERIFICATION_URI="$(jq -r '.verification_uri' <<< "${DEVICE_CODE_RESPONSE}")"
	VERIFICATION_URI_COMPLETE="$(jq -r '.verification_uri_complete' <<< "${DEVICE_CODE_RESPONSE}")"
	EXPIRY_TIME="$(jq -r '.expires_in' <<< "${DEVICE_CODE_RESPONSE}")"
	INTERVAL="$(jq -r '.interval' <<< "${DEVICE_CODE_RESPONSE}")"
	log "Retrieved device code ${DEVICE_CODE}"
	log "Polling for token every ${INTERVAL}s."

	printf "\n"
	log "Visit ${VERIFICATION_URI} and input code \'${USER_CODE}' to authorize this device."
	log "Alternatively visit ${VERIFICATION_URI_COMPLETE}"
	printf "\n"

	TOKEN_RESPONSE="$(poll_for_token ${DEVICE_CODE} ${INTERVAL} ${EXPIRY_TIME})"
	if [ "${TOKEN_RESPONSE}" = 1 ]; then
		log_error "Reponse for token failed."
		exit 1
	elif [ "${TOKEN_RESPONSE}" = 2 ]; then
		log_error "Verification code expired after ${3}s."
		exit 1
	fi

	log "Verification successful."
fi

ACCESS_TOKEN="$(jq -r '.access_token' <<< "${TOKEN_RESPONSE}")"
REFRESH_TOKEN="$(jq -r '.refresh_token' <<< "${TOKEN_RESPONSE}")"
log "Token response successful."
echo "${REFRESH_TOKEN}" > ".refresh_token"
log "Saved new refresh token to .refresh_token."

log "Requesting for available profiles."
PROFILES_RESPONSE="$(request_profiles ${ACCESS_TOKEN})"
if [ "${PROFILES_RESPONSE}" = 1 ]; then
	log_error "Reponse for available profiles failed."
	exit 1
fi

UUID="$(jq -r '.profiles.[].uuid' <<< "${PROFILES_RESPONSE}")"
USERNAME="$(jq -r '.profiles.[].username' <<< "${PROFILES_RESPONSE}")"
log "Retrieved UUID ${UUID} of user ${USERNAME}."
export OWNER_UUID="${UUID}"
export OWNER_NAME="${USERNAME}"

log "Creating game session."
GAME_SESSION_RESPONSE="$(create_game_session ${ACCESS_TOKEN} ${UUID})"
if [ "${GAME_SESSION_RESPONSE}" = 1 ]; then
	log_error "Reponse for creating game session failed."
	exit 1
fi

SESSION_TOKEN="$(jq -r '.sessionToken' <<< "${GAME_SESSION_RESPONSE}")"
IDENTITY_TOKEN="$(jq -r '.identityToken' <<< "${GAME_SESSION_RESPONSE}")"
log "Game session successfully created."

grep -qsF 'SESSION_TOKEN=' "${1}" || { echo 'SESSION_TOKEN=' >> "${1}"; } > /dev/null 2>&1
grep -qsF 'IDENTITY_TOKEN=' "${1}" || { echo 'IDENTITY_TOKEN=' >> "${1}"; } > /dev/null 2>&1
grep -qsF 'OWNER_UUID=' "${1}" || { echo 'OWNER_UUID=' >> "${1}"; } > /dev/null 2>&1
grep -qsF 'OWNER_NAME=' "${1}" || { echo 'OWNER_NAME=' >> "${1}"; } > /dev/null 2>&1
sed -i "s/SESSION_TOKEN=.*/SESSION_TOKEN=${SESSION_TOKEN}/g" "${1}" > /dev/null 2>&1
sed -i "s/IDENTITY_TOKEN=.*/IDENTITY_TOKEN=${IDENTITY_TOKEN}/g" "${1}" > /dev/null 2>&1 
sed -i "s/OWNER_UUID=.*/OWNER_UUID=${UUID}/g" "${1}" > /dev/null 2>&1
sed -i "s/OWNER_NAME=.*/OWNER_NAME=${USERNAME}/g" "${1}" > /dev/null 2>&1
if [ "$?" -ne 0 ]; then
	log_error "Failed to save credentials to .env. Did you properly specify the env file?"
else
	log "Saved credentials to .env."
fi
