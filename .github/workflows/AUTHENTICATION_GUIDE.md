# GitHub Authentication Guide

## Overview

GitHub operations that require authentication (push, pull, PR creation) must be run **outside the sandbox** to access system credentials.

## Commands Requiring Unsandboxed Execution

The following commands need `required_permissions: ["all"]` or manual execution:

### Git Operations
```bash
git push
git push -u origin <branch>
git pull
git fetch --all
```

### GitHub CLI Operations
```bash
gh pr create
gh pr merge
gh pr list
gh pr view
gh auth status
gh auth login
```

## Recommended Workflow

### Option 1: Run Commands Manually
When prompted for push/PR operations, run them in your terminal:
```bash
# 1. Push changes
git push -u origin <branch-name>

# 2. Create PR
gh pr create --title "Your Title" --body "Description" --base master

# 3. Merge PR
gh pr merge --squash --delete-branch
```

### Option 2: Use Helper Script
We've created a helper script for common workflows:

```bash
# Make script executable (first time only)
chmod +x .github/scripts/github-workflow.sh

# Use it for complete workflow
./.github/scripts/github-workflow.sh
```

## Why This Is Needed

**Sandbox Restrictions:**
- The sandbox blocks access to macOS Keychain
- GitHub credentials are stored in Keychain
- Authentication requires unsandboxed execution

**Security Note:**
Running with `required_permissions: ["all"]` temporarily disables sandbox restrictions for that specific command only.

## Troubleshooting

### "Failed to get credentials" Error
```bash
# Re-authenticate GitHub CLI
gh auth login

# Check authentication status
gh auth status
```

### "Device not configured" Error
This means credentials are not accessible in the sandbox. Run the command manually or with `required_permissions: ["all"]`.

### SwiftLint Hook Issues
If the pre-commit hook fails with SwiftLint errors about `--path`:
```bash
# Commit with verification skip (if code is verified clean)
git commit --no-verify -m "your message"
```

## Pre-commit Hook Behavior

The `.git/hooks/pre-commit` script:
1. ✅ Blocks direct commits to `master` branch
2. ✅ Runs SwiftLint on staged Swift files
3. ✅ Allows bypass with `--no-verify` flag

**Note:** SwiftLint pre-commit hook currently has a bug with `--path` option. This should be fixed in the hook script.

