#!/bin/bash
set -e


# Ensure exactly 2 arguments (owner and repo) are provided.
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <owner> <repo>"
  exit 1
fi

OWNER="$1"
REPO="$2"

echo "OWNER: $OWNER"
echo "REPO: $REPO"

# Verify that GITHUB_TOKEN is set.
if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: Please export your GitHub token in the GITHUB_TOKEN environment variable."
  exit 1
fi

# Read the entire stdin as the issue content.
ISSUE_BODY=$(cat)

# Use the first non-empty line as the issue title.
TITLE=$(echo "$ISSUE_BODY" | sed '/^[[:space:]]*$/d' | head -n 1)
if [ -z "$TITLE" ]; then
  TITLE="New issue"
fi

# Build the JSON payload using jq for proper escaping.
JSON_PAYLOAD=$(jq -n --arg title "$TITLE" --arg body "$ISSUE_BODY" \
  '{title: $title, body: $body}')

# Post the issue via GitHub API.
RESPONSE=$(curl -s -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD" \
  "https://api.github.com/repos/${OWNER}/${REPO}/issues")

echo "$RESPONSE"
