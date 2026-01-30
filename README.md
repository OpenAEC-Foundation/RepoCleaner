# OpenAEC Foundation - Repository License Manager

This directory contains tools to apply the LGPL 3.0 license to all repositories in the OpenAEC-Foundation GitHub organization.

## Contents

- **LICENSE.md** - The complete LGPL 3.0 license text (includes GPL 3.0 + LGPL additions)
- **apply_license.sh** - Script to apply the license via GitHub API (fast, no cloning needed)

## Prerequisites

1. Install GitHub CLI: https://cli.github.com/
2. Install jq (JSON processor): `sudo apt install jq` or `brew install jq`
3. Authenticate with GitHub:
   ```bash
   gh auth login
   ```
4. Ensure you have write access to the OpenAEC-Foundation repositories

## Usage

Apply the license to all repositories:

```bash
./apply_license.sh
```

Dry run to see what would be changed without making changes:
```bash
./apply_license.sh --dry-run
```

## How it works

1. Fetches all repositories from the OpenAEC-Foundation organization
2. For each repository:
   - Checks if LICENSE.md already exists via GitHub API
   - If it exists, downloads and compares content with local LICENSE.md
   - **Skips if identical** (won't create duplicate commits)
   - If different or missing, creates/updates via API
   - Commits directly to the default branch (no cloning needed)
3. Provides a summary of successes, skips, and failures

**Advantages:**
- Very fast (uses GitHub API, no cloning)
- No disk space needed
- Handles large repositories efficiently
- Smart skipping prevents duplicate commits

## Notes

- **Automatic skipping:** Repositories with an identical LICENSE.md are automatically skipped
- Empty repositories are skipped
- Each repository is processed sequentially
- Failed operations are reported in the summary

## License

This tooling applies the GNU Lesser General Public License v3.0 (LGPL-3.0) to all OpenAEC-Foundation repositories.
