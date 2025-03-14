#!/bin/bash
# Script: create_and_watch_issue.sh
# Description:
#   - Create a new GitHub issue.
#   - Wait until the issue is closed.
#   - If the issue is marked with a label containing "completed" (case-insensitive),
#     create an annotated Git tag and push it.
#
# Requirements:
#   - GitHub CLI (gh) must be installed and authenticated.
#   - jq must be installed.
#
# Usage:
#   ./create_and_watch_issue.sh "Issue Title" "Issue Body (optional)" "owner/repo"
#
# Example:
#   ./create_and_watch_issue.sh "Implement feature X" "Please implement..." myuser/myrepo

# Check for required commands.
if ! command -v gh >/dev/null 2>&1; then
  echo "GitHub CLI (gh) is required but not installed."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required but not installed."
  exit 1
fi

# Get parameters.
ISSUE_TITLE="$1"
REPO="$2"
ISSUE_BODY=$(cat)

if [ -z "$ISSUE_TITLE" ] || [ -z "$REPO" ]; then
  echo "Usage: $0 \"Issue Title\" \"Issue Body\" owner/repo"
  exit 1
fi

# Create a new issue.
# Without --json support, gh prints the URL of the new issue.
echo "Creating new issue: $ISSUE_TITLE"
issue_url=$(gh issue create --repo "$REPO" --title "$ISSUE_TITLE" --body "$ISSUE_BODY")
if [ -z "$issue_url" ]; then
  echo "Failed to create issue."
  exit 1
fi

# Extract the issue number from the issue URL.
# The URL is expected to be of the form: https://github.com/owner/repo/issues/123
ISSUE_NUMBER=$(echo "$issue_url" | awk -F'/' '{print $NF}')

echo "Issue #$ISSUE_NUMBER created successfully in $REPO."
echo "Issue URL: $issue_url"

# Define a function to fetch issue details via GitHub API.
get_issue_json() {
  gh api repos/"${REPO}"/issues/"${ISSUE_NUMBER}"
}

# Poll until the issue is closed.
echo "Waiting for issue #$ISSUE_NUMBER to be closed..."
while true; do
    # Fetch the issue details in JSON.
    issue_data=$(get_issue_json)
    # Extract the state field.
    state=$(echo "$issue_data" | jq -r '.state')
    reason=$(echo "$issue_data" | jq -r '.state_reason')
    if [ "$state" == "closed" ]; then
        break
    fi
    # Sleep 10 seconds between polls.
    sleep 10
done
echo "Issue #$ISSUE_NUMBER is now closed."

if [[ "$reason" == "completed" ]]; then
    echo "Issue #$ISSUE_NUMBER is marked as completed. Creating a tag."
    exit 0
else
    echo "Issue #$ISSUE_NUMBER is not marked as completed. No tag will be created."
    exit 1
fi

