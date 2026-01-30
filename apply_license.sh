#!/bin/bash

# Script to apply LGPL 3.0 license to all OpenAEC-Foundation repositories using GitHub API
# Usage: ./apply_license_api.sh [--dry-run]

set -e

ORG="OpenAEC-Foundation"
LICENSE_FILE="$(dirname "$0")/LICENSE.md"

# Parse arguments
DRY_RUN=false
[ "$1" == "--dry-run" ] && DRY_RUN=true

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "================================================"
echo "  LGPL 3.0 License Installer (API Mode)"
echo "  Organization: ${ORG}"
[ "$DRY_RUN" == true ] && echo -e "  ${BLUE}MODE: DRY RUN (no changes)${NC}"
echo "================================================"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}Error: gh CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://cli.github.com/"
    exit 1
fi

# Check if license file exists
if [ ! -f "$LICENSE_FILE" ]; then
    echo -e "${RED}Error: LICENSE.md not found at ${LICENSE_FILE}${NC}"
    exit 1
fi

# Base64 encode the license file (required for GitHub API)
LICENSE_CONTENT=$(base64 -w 0 "$LICENSE_FILE")

echo -e "${GREEN}Fetching repositories from ${ORG}...${NC}"
echo ""

# Get all repos from the organization
repos=$(gh repo list "$ORG" --limit 1000 --json name,defaultBranchRef --jq '.[] | "\(.name)|\(.defaultBranchRef.name)"')

if [ -z "$repos" ]; then
    echo -e "${RED}No repositories found or authentication failed.${NC}"
    echo "Please run: gh auth login"
    exit 1
fi

# Count repos
repo_count=$(echo "$repos" | wc -l)
echo -e "${GREEN}Found ${repo_count} repositories${NC}"
echo ""

current=0
success=0
skipped=0
failed=0

# Process each repository
while IFS='|' read -r repo default_branch; do
    current=$((current + 1))
    echo "================================================"
    echo -e "${YELLOW}[$current/$repo_count] Processing: ${repo}${NC}"
    echo "================================================"

    if [ -z "$default_branch" ]; then
        echo -e "${YELLOW}Empty repository, skipping...${NC}"
        skipped=$((skipped + 1))
        echo ""
        continue
    fi

    echo "Default branch: ${default_branch}"

    # Check if LICENSE.md already exists
    existing_sha=""
    if gh api "repos/${ORG}/${repo}/contents/LICENSE.md" --silent 2>/dev/null; then
        echo -e "${YELLOW}LICENSE.md already exists, checking content...${NC}"

        # Get existing file content and SHA
        existing_content=$(gh api "repos/${ORG}/${repo}/contents/LICENSE.md" --jq '.content' | base64 -d)
        existing_sha=$(gh api "repos/${ORG}/${repo}/contents/LICENSE.md" --jq '.sha')

        # Compare with our license
        if [ "$existing_content" == "$(cat "$LICENSE_FILE")" ]; then
            echo -e "${GREEN}LICENSE.md is already up to date, skipping...${NC}"
            skipped=$((skipped + 1))
            echo ""
            continue
        else
            echo "LICENSE.md differs, updating..."
        fi
    fi

    if [ "$DRY_RUN" == true ]; then
        if [ -n "$existing_sha" ]; then
            echo -e "${BLUE}[DRY RUN] Would update LICENSE.md${NC}"
        else
            echo -e "${BLUE}[DRY RUN] Would create LICENSE.md${NC}"
        fi
        success=$((success + 1))
        echo ""
        continue
    fi

    # Prepare API request payload
    commit_message="Add LGPL 3.0 license

This commit adds the GNU Lesser General Public License v3.0 to the repository.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

    # Build JSON payload
    if [ -n "$existing_sha" ]; then
        # Update existing file
        payload=$(jq -n \
            --arg msg "$commit_message" \
            --arg content "$LICENSE_CONTENT" \
            --arg sha "$existing_sha" \
            --arg branch "$default_branch" \
            '{message: $msg, content: $content, sha: $sha, branch: $branch}')
    else
        # Create new file
        payload=$(jq -n \
            --arg msg "$commit_message" \
            --arg content "$LICENSE_CONTENT" \
            --arg branch "$default_branch" \
            '{message: $msg, content: $content, branch: $branch}')
    fi

    # Make API request to create/update file
    if gh api "repos/${ORG}/${repo}/contents/LICENSE.md" \
        --method PUT \
        --input - <<< "$payload" \
        --silent > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Successfully added license to ${repo}${NC}"
        success=$((success + 1))
    else
        echo -e "${RED}✗ Failed to add license to ${repo}${NC}"
        failed=$((failed + 1))
    fi

    echo ""
done <<< "$repos"

# Summary
echo "================================================"
echo "  SUMMARY"
echo "================================================"
echo -e "Total repositories: ${repo_count}"
if [ "$DRY_RUN" == true ]; then
    echo -e "${BLUE}Would update: ${success}${NC}"
else
    echo -e "${GREEN}Successfully updated: ${success}${NC}"
fi
echo -e "${YELLOW}Skipped (already up to date): ${skipped}${NC}"
echo -e "${RED}Failed: ${failed}${NC}"
echo "================================================"

if [ $failed -gt 0 ]; then
    exit 1
fi
