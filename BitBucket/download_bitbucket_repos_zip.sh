#!/bin/bash

# Configurations
USERNAME="surbhial-admin"
PASSWORD=""
WORKSPACE="surbhial" # Replace with your workspace name
API_URL="https://api.bitbucket.org/2.0/repositories/${WORKSPACE}"
OUTPUT_DIR="repos" # Directory to store downloaded zips
PAGE=1

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

echo "Fetching repositories from workspace: $WORKSPACE"

while true; do
    # Fetch repositories page by page
    RESPONSE=$(curl -su "${USERNAME}:${PASSWORD}" --request GET "${API_URL}?page=${PAGE}" -s)
    
    # Extract repository slugs
    REPO_SLUGS=$(echo "$RESPONSE" | jq -r '.values[].slug')

    # Exit loop if no repositories found
    if [[ -z "$REPO_SLUGS" ]]; then
        echo "No more repositories found."
        break
    fi

    for REPO_SLUG in $REPO_SLUGS; do
        ZIP_URL_MAIN="https://bitbucket.org/${WORKSPACE}/${REPO_SLUG}/get/main.zip"
        ZIP_URL_MASTER="https://bitbucket.org/${WORKSPACE}/${REPO_SLUG}/get/master.zip"
        OUTPUT_FILE="${OUTPUT_DIR}/${REPO_SLUG}.zip"

        echo "Downloading $REPO_SLUG..."

        # Try main.zip
        if curl --fail --location -u "${USERNAME}:${PASSWORD}" "$ZIP_URL_MAIN" -o "$OUTPUT_FILE"; then
            echo "Downloaded main.zip for $REPO_SLUG"
        # Fallback to master.zip
        elif curl --fail --location -u "${USERNAME}:${PASSWORD}" "$ZIP_URL_MASTER" -o "$OUTPUT_FILE"; then
            echo "Downloaded master.zip for $REPO_SLUG"
        else
            echo "Failed to download $REPO_SLUG (main.zip and master.zip not found)"
        fi
    done

    # Check if there is a "next" page
    NEXT_PAGE=$(echo "$RESPONSE" | jq -r '.next // empty')
    if [[ -z "$NEXT_PAGE" ]]; then
        echo "All repositories processed."
        break
    fi

    # Increment page
    PAGE=$((PAGE + 1))
done

echo "All repositories downloaded."

