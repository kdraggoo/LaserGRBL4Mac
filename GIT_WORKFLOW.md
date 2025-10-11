# Git Workflow Guide

## Quick Start

### 1. Create a Feature Branch
```bash
# Before making any changes
git checkout -b feature/descriptive-name

# Or for bug fixes
git checkout -b fix/bug-description
```

### 2. Make Your Changes
- Edit files as needed
- Test your changes
- Run SwiftLint: `swiftlint --fix` (optional but recommended)

### 3. Stage and Commit
```bash
# Stage your changes
git add .

# Commit with a good message
git commit

# The hooks will automatically run:
# ✓ Check you're not on main/master
# ✓ Lint your Swift code
# ✓ Validate your commit message
```

### 4. Good Commit Message Template
```
feat(component): short description under 72 chars

More detailed explanation of what changed and why.
- What was the problem?
- How does this change solve it?
- Any important details to note?

For large changes (>20 lines), a body is required.
```

## Current Branch Status

You are currently on: **master** branch

⚠️ **You need to create a feature branch before committing!**

```bash
# If you have unstaged changes:
git checkout -b feature/your-feature-name

# If you have staged changes:
git reset --soft HEAD
git checkout -b feature/your-feature-name
git add .
git commit -m "Your commit message"
```

## Branch Naming Conventions

- `feature/` - New features or enhancements
  - Example: `feature/zoom-controls`
  - Example: `feature/gcode-validator`

- `fix/` - Bug fixes
  - Example: `fix/preview-rendering`
  - Example: `fix/file-loading-crash`

- `refactor/` - Code improvements without changing functionality
  - Example: `refactor/split-large-functions`
  - Example: `refactor/cleanup-preview-view`

- `docs/` - Documentation updates
  - Example: `docs/update-readme`
  - Example: `docs/add-api-docs`

- `test/` - Adding or updating tests
  - Example: `test/add-gcode-parser-tests`

- `chore/` - Maintenance tasks
  - Example: `chore/update-dependencies`
  - Example: `chore/configure-linter`

## Commit Message Format

### Required Format for Large Changes (>20 lines)

```
type(scope): subject line (10-72 characters)

Body paragraph explaining:
- What changed
- Why it changed
- How it impacts the codebase

Can have multiple paragraphs if needed.
```

### Conventional Commit Types

- `feat:` - A new feature
- `fix:` - A bug fix
- `docs:` - Documentation only changes
- `style:` - Code style/formatting (no logic change)
- `refactor:` - Code change that neither fixes a bug nor adds a feature
- `test:` - Adding or correcting tests
- `chore:` - Changes to build process or auxiliary tools
- `perf:` - Performance improvements

### Examples

✅ Good:
```
feat(preview): add zoom in/out buttons

Added zoom controls to the GCode preview panel including:
- Zoom in/out buttons
- Fit to view button  
- Keyboard shortcuts (Cmd+/Cmd-)

This improves UX when working with large files.
```

✅ Good (simple):
```
fix: correct calculation for preview bounds
```

✅ Good:
```
refactor(preview): split drawCommands into smaller functions

The drawCommands function exceeded 100 lines. Split into:
- drawPath() - handles path rendering
- calculateBounds() - boundary computation  
- applyTransform() - zoom/pan transforms

Improves readability and testability.
```

❌ Bad:
```
update
```

❌ Bad:
```
wip
```

❌ Bad:
```
fix stuff
```

## SwiftLint Integration

Automatically runs on commit for all staged Swift files.

### Auto-fix Issues
```bash
# Fix many issues automatically
swiftlint --fix

# Check current violations
swiftlint lint

# Check specific file
swiftlint lint --path path/to/file.swift
```

### Common Issues

- **Trailing newlines** - Files should end with a single newline
- **Trailing commas** - Remove trailing commas in arrays/dictionaries
- **Force unwrapping** - Use safe optional unwrapping instead of `!`
- **Long functions** - Break functions >50 lines into smaller pieces
- **Line length** - Keep lines under 120 characters

## Bypassing Hooks (Emergency Only)

```bash
git commit --no-verify
```

⚠️ **Only use this in exceptional circumstances!** Hooks exist to maintain code quality.

## Workflow Example

```bash
# 1. Start new feature
git checkout -b feature/laser-power-control

# 2. Make changes
# ... edit files ...

# 3. Run linter (optional)
swiftlint --fix

# 4. Stage changes
git add LaserGRBL-macOS/Views/LaserControlView.swift

# 5. Commit (hooks run automatically)
git commit

# Hooks will:
# ✓ Verify you're not on main/master  
# ✓ Run SwiftLint on staged files
# ✓ Validate commit message quality

# 6. Push to remote
git push origin feature/laser-power-control

# 7. Create pull request on GitHub/GitLab
```

## Getting Help

- **Hook documentation:** `.git/hooks/README.md`
- **SwiftLint config:** `.swiftlint.yml`
- **Pre-commit hook:** `.git/hooks/pre-commit`
- **Commit-msg hook:** `.git/hooks/commit-msg`

## Requirements

- Git (installed)
- SwiftLint: `brew install swiftlint`
- Working on a feature branch (not main/master)

