# LaserGRBL macOS - Quick Reference

## 🚀 Quick Start Development Workflow

### One-Command Workflow (Recommended)
```bash
./git-helper.sh full
```
This handles everything: commit → push → PR → merge

### Step-by-Step Workflow
```bash
# 1. Create feature branch
./git-helper.sh branch feature/my-feature

# 2. Make your changes...

# 3. Commit
./git-helper.sh commit

# 4. Push to GitHub
./git-helper.sh push

# 5. Create PR
./git-helper.sh pr

# 6. Merge when ready
./git-helper.sh merge
```

## 📝 Common Commands

| Command | What It Does |
|---------|--------------|
| `./git-helper.sh full` | Complete workflow (commit → push → PR → merge) |
| `./git-helper.sh commit` | Stage and commit all changes |
| `./git-helper.sh push` | Push current branch to GitHub |
| `./git-helper.sh pr` | Create pull request |
| `./git-helper.sh merge` | Merge and delete PR branch |
| `./git-helper.sh branch <name>` | Create new feature branch |
| `./git-helper.sh help` | Show detailed help |

## 🔐 Why Use git-helper.sh?

**Problem:** Git push and GitHub CLI commands require Keychain access
**Solution:** Helper script runs outside sandbox with proper authentication

Without helper (fails):
```bash
git push  # ❌ Error: Device not configured
```

With helper (works):
```bash
./git-helper.sh push  # ✅ Success
```

## 🛠️ Build & Run

```bash
# Open in Xcode
open LaserGRBL-macOS/LaserGRBL/LaserGRBL.xcodeproj

# Or build from command line
xcodebuild -project LaserGRBL-macOS/LaserGRBL/LaserGRBL.xcodeproj \
           -scheme LaserGRBL \
           -configuration Debug \
           build
```

## 📚 Documentation

- **Development Workflow:** [.github/README.md](.github/README.md)
- **Authentication Guide:** [.github/workflows/AUTHENTICATION_GUIDE.md](.github/workflows/AUTHENTICATION_GUIDE.md)
- **Git Workflow:** [GIT_WORKFLOW.md](GIT_WORKFLOW.md)
- **Contributing:** [CONTRIBUTING.md](CONTRIBUTING.md)

## 🎯 Project Status

| Phase | Status | Features |
|-------|--------|----------|
| Phase 1-3 | ✅ Complete | Core G-code, USB, Real-time control |
| Phase 4 | ✅ Complete | Unified Import (SVG + Image) |
| **Phase 5** | **✅ Complete** | **8 Essential Features (Overrides, Settings, Help, etc.)** |
| Phase 6 | 📋 Planned | Advanced features |
| Phase 7 | 📋 Planned | Polish & Distribution |

**Current Version:** Phase 5 Complete  
**Ready for:** Production Testing

## 🐛 Troubleshooting

### "Permission Denied" when running git-helper.sh
```bash
chmod +x git-helper.sh
chmod +x .github/scripts/github-workflow.sh
```

### "Not on a feature branch" error
```bash
# Create a feature branch first
./git-helper.sh branch feature/my-feature
```

### SwiftLint errors in pre-commit hook
```bash
# If code is verified clean, bypass hook:
git commit --no-verify -m "your message"
```

### GitHub CLI not authenticated
```bash
gh auth login
gh auth status
```

## 💡 Tips

- Always work on feature branches (never commit directly to master)
- Use `./git-helper.sh full` for routine workflows
- Pre-commit hook enforces branch protection
- SwiftLint runs automatically (can bypass with --no-verify)
- Helper script provides interactive prompts for all inputs

## 🔗 Links

- **Repository:** https://github.com/kdraggoo/LaserGRBL4Mac
- **Original Windows Version:** https://github.com/arkypita/LaserGRBL
- **GRBL Documentation:** https://github.com/gnea/grbl/wiki

---

**Need Help?** Run `./git-helper.sh help` or check [.github/README.md](.github/README.md)

