#!/usr/bin/env bash

# This script is used to combine all plugins into one run and publish
# Usage: ./publish.sh [-v|--verbose]

set -euo pipefail

# Always run from repo root regardless of where the script is invoked
cd "$(dirname "$0")/.."

exec > >(tee publish.log) 2>&1

# verbose mode keeps the publish.log file, otherwise it is deleted on successful exit
VERBOSE=false
if [[ "${1:-}" == "-v" || "${1:-}" == "--verbose" ]]; then
  VERBOSE=true
fi

cleanup() {
  local exit_code=$?
  if [ $exit_code -eq 0 ] && [ "$VERBOSE" = false ]; then
    rm -f publish.log
  fi
}
trap cleanup EXIT

# Load the env vars from _environment file
if [ -f "_environment" ]; then
  set -a
  . _environment
  set +a
else
  echo "_environment file not found. Please create one with the necessary environment variables."
  exit 1
fi

# Translate current Windows path to WSL mount path
WSL_DIR=$(wsl wslpath -u "$(pwd -W)")

# Run plugins in a single WSL session (where jq is available)
wsl bash << EOF
set -euo pipefail
cd '$WSL_DIR'
set -a && . _environment && set +a

plugins/discogs.sh syrchanan db || true
plugins/goodreads.sh "\$GOODREADS_WIDGET" db || true
EOF

# Publish the site (quarto runs on Windows)
quarto publish gh-pages .
