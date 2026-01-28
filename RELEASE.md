# Release Process

## Prerequisites

Before creating a release, ensure:

- ✅ All tests pass (`testing/circuit-breaker-tests.md`, `testing/cli-tests.md`)
- ✅ CHANGELOG.md updated with version notes
- ✅ Version bump in README.md (badge)
- ✅ All documentation updated
- ✅ Security review completed (for non-alpha releases)

---

## Versioning

Moltbot Hardened follows [Semantic Versioning 2.0.0](https://semver.org/):

- **MAJOR** (X.0.0): Incompatible API changes
- **MINOR** (0.X.0): Backwards-compatible functionality
- **PATCH** (0.0.X): Backwards-compatible bug fixes

### Alpha/Beta/RC

- **alpha** (vX.X.X-alpha): Experimental, breaking changes likely
- **beta** (vX.X.X-beta): Feature complete, testing needed
- **rc** (vX.X.X-rc): Release candidate, final testing

Example:
- `v0.2.0-alpha` → Alpha release for Phase 2
- `v0.2.0-beta` → Beta release with Phase 2 features
- `v0.2.0` → Production-ready release (future)

---

## Steps to Release

### 1. Create Release Branch

```bash
# From main branch
git checkout main
git pull origin main

# Create release branch
git checkout -b release/v0.2.0-alpha
```

### 2. Update CHANGELOG.md

```markdown
## v0.2.0-alpha (2026-01-28)

### Added
- [List new features]

### Changed
- [List breaking changes]

### Fixed
- [List bug fixes]

### Notes
- [Important notes, warnings, deprecations]
```

### 3. Update README.md

Update version badges:

```markdown
[![Status](https://img.shields.io/badge/status-alpha-orange)]
[![Version](https://img.shields.io/badge/version-0.2.0--alpha-blue)]
```

### 4. Commit Changes

```bash
git add CHANGELOG.md README.md
git commit -m "chore: prepare for v0.2.0-alpha release"
```

### 5. Create Git Tag

```bash
# Annotated tag with release notes
git tag -a v0.2.0-alpha -m "Release v0.2.0-alpha

Features:
- Guardian automation
- CLI wrapper with status/block/recovery/open/verify
- Installation scripts

See CHANGELOG.md for details."
```

### 6. Push to GitHub

```bash
# Push branch and tag
git push origin release/v0.2.0-alpha
git push origin v0.2.0-alpha
```

### 7. Create GitHub Release

1. Go to: https://github.com/VanessaPellegrini/moltbot-hardened/releases
2. Click "Draft a new release"
3. Choose tag: `v0.2.0-alpha`
4. Title: `Release v0.2.0-alpha`
5. Description: Copy from CHANGELOG or tag message
6. Set as "Pre-release" (for alpha/beta)
7. Click "Publish release"

### 8. Merge Back to Main

```bash
# After release is published
git checkout main
git merge release/v0.2.0-alpha
git push origin main

# Optional: Delete release branch
git branch -d release/v0.2.0-alpha
git push origin --delete release/v0.2.0-alpha
```

---

## Post-Release Checklist

After release is published:

- [ ] Update project website (if exists)
- [ ] Announce on community channels (Discord, etc.)
- [ ] Update documentation references
- [ ] Close related GitHub issues with release notes
- [ ] Create GitHub milestone for next release
- [ ] Update roadmap/roadmap.md

---

## Hotfix Process

For critical fixes:

```bash
# From main, create hotfix branch
git checkout -b hotfix/v0.2.1

# Fix issue and test
# ...

# Commit fix
git commit -m "fix: critical security issue"

# Create patch release tag
git tag -a v0.2.1 -m "Hotfix v0.2.1"

# Push
git push origin main
git push origin v0.2.1

# Create GitHub release (pre-release or normal)
```

---

## Release Notes Template

```markdown
## Version vX.X.X (YYYY-MM-DD)

### 🚀 New Features
- [Feature 1]
- [Feature 2]

### 🔄 Changes
- [Breaking change 1]
- [Behavior change 2]

### 🐛 Bug Fixes
- [Bug fix 1]
- [Bug fix 2]

### 📚 Documentation
- [Doc update 1]
- [Doc update 2]

### ⚠️ Known Issues
- [Issue 1]
- [Issue 2]

### ⚡ Upgrade Notes
- [Important upgrade instructions]
- [Breaking changes that affect users]

---

**Full Changelog:** https://github.com/VanessaPellegrini/moltbot-hardened/blob/main/CHANGELOG.md
```

---

*Last updated: 2026-01-28*
