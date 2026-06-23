#!/bin/bash

# Get the current Git tag, commit hash, or fall back to 'unversioned'
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Inside a Git repo
    if APP_VERSION=$(git describe --tags --exact-match 2>/dev/null); then
        # Use the exact tag if available
        APP_VERSION="/tree/$APP_VERSION"
    elif APP_VERSION=$(git rev-parse HEAD 2>/dev/null); then
        # Fall back to commit hash if no tag
        APP_VERSION="/commit/$APP_VERSION"
    else
        APP_VERSION="unversioned"
    fi
else
    # Not in a Git repo
    APP_VERSION="unversioned"
fi

# Export the result
echo "starting Decide stack with APP_VERSION=$APP_VERSION"
APP_VERSION=$APP_VERSION docker compose up -d