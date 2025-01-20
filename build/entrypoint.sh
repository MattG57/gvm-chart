#!/bin/bash

chown -R 1001:1001 /app

# Switch to user 1001 and execute the passed command
exec su-exec 1001:1001 "$@"

set -e

# Write environment variables to backend/.env
echo "Initializing backend environment variables..."
env | grep -E '^PORT_|^GIT_|^BASE_' > /app/backend/.env

# Start the frontend and backend applications
echo "Starting frontend and backend..."
cd /app/backend && npm run start
