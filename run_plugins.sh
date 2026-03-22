#!/usr/bin/env bash

# This script is used to combine all plugins into one run

# Exit immediately if a command exits with a non-zero status.
set -euo pipefail

# Load the env vars from _environment file
if [ -f "_environment" ]; then
  set -a
  . _environment
  set +a
else
  echo "_environment file not found. Please create one with the necessary environment variables."
  exit 1
fi

# Run plugins
./plugins/discogs.sh syrchanan db

./plugins/goodreads.sh "$GOODREADS_WIDGET" db