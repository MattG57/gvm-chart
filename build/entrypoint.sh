#!/bin/bash
set -e



# Write environment variables to backend/.env
echo "Entrypoint.sh Initializing backend environment variables..."
env | grep -E '^PORT$|^PORT_|^GIT_|^BASE_' > /app/backend/.env
set


# Execute the passed command
exec "$@"