#!/bin/bash
set -e

# Set ownership
chown -R 1001:1001 /app

# Write environment variables to backend/.env
echo "Entrypoint.sh Initializing backend environment variables..."
env | grep -E '^PORT$|^PORT_|^GIT_|^BASE_' > /app/backend/.env

# Switch to user 1001 and execute the passed command
exec gosu 1001:1001 sh -c "$@"