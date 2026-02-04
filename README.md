# OpenAEC Foundation - Convention Enforcer

Automatically checks and fixes coding conventions across OpenAEC-Foundation repositories.

## What it does

- Fetches conventions from `OpenAEC-Foundation/conventions`
- Checks repositories for convention violations
- Automatically fixes violations where possible (with `--fix-*` flags)
- Flags complex cases for manual review
- Creates/updates a pinned GitHub issue in `.github` repo tracking all violations (check mode only)

## Current features

- Repository naming conventions (kebab-case, max 3 segments)
- License management (LGPL 3.0)
- String case conversion utility

## Usage

Check conventions:
```bash
./repo_conventions_enforcer.py --repo-naming          # Check all repos
./repo_conventions_enforcer.py --repo-naming --single-repo RepoCleaner  # Check one repo
./repo_conventions_enforcer.py --licenses             # Check licenses
```

Fix violations (⚠️ DANGEROUS - modifies repositories):
```bash
./repo_conventions_enforcer.py --fix-repo-naming      # Rename repos to fix naming
./repo_conventions_enforcer.py --fix-licenses         # Apply/update licenses
```

**Warning**: `--fix-*` flags modify repositories directly. Always run check-only mode first and review the changes carefully before using fix mode.

Convert strings:
```bash
./repo_conventions_enforcer.py --string-naming kebab-case "OpenPDFStudio"
```

## Prerequisites

- Python 3.11+
- GitHub CLI: https://cli.github.com/
- Dependencies: `pip install pyyaml`
- Authenticated: `gh auth login`

## License

LGPL 3.0
