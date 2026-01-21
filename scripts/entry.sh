#!/bin/bash

source "$(dirname "$0")/utils.sh"

# Check system ARCH 
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
	log_error "Hytale servers only support x86_64 architecture currently."
	log_error "Current architecture: ${ARCH}"
	exit 1
fi

exec "$(dirname "$0")/download_server.sh" 
