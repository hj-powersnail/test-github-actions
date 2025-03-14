#!/bin/bash
set -e

# Ensure exactly 1 argument (repo) is provided.
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <repo>"
  exit 1
fi

REPO="$1"
echo "REPO: $REPO"

# Verify that GITHUB_TOKEN is set.
if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: Please export your GitHub token in the GITHUB_TOKEN environment variable."
  exit 1
fi

# Read the first line from stdin as the issue title.
if ! read -r TITLE; then
  echo "Error: No input provided for the issue."
  exit 1
fi

# Read the rest of the stdin as the issue body.
BODY=$(cat)

# Build the JSON payload using jq for proper escaping.
JSON_PAYLOAD=$(jq -n --arg title "$TITLE" --arg body "$BODY" '{title: $title, body: $body}')

# Post the issue via GitHub API.
RESPONSE=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "https://api.github.com/repos/${REPO}/issues")

echo "$RESPONSE"
