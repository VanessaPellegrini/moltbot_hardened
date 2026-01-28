# Contributing to Moltbot Hardened

Thank you for your interest in contributing to Moltbot Hardened! This project is in **alpha/experimental** stage, so contributions are especially valuable.

## Status

**⚠️ This project is ALPHA/EXPERIMENTAL**

- Not production-ready
- No guarantees of stability or security
- APIs and configurations may change without notice
- Use at your own risk

## Getting Started

1. **Fork the repository**
2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes**
4. **Test thoroughly**
   - Run existing tests in `/testing/`
   - Add new tests if adding features
5. **Commit with clear messages**
   - Use conventional commits: `feat:`, `fix:`, `docs:`, etc.
6. **Push and create a Pull Request**

## Development Workflow

### Local Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/moltbot-hardened.git
cd moltbot-hardened

# Install dependencies
# See INSTALL.md for detailed instructions

# Verify installation
moltbot-hardened status
```

### Testing

All changes must be tested:

```bash
# Run circuit breaker tests
# See testing/circuit-breaker-tests.md

# Run CLI tests
# See testing/cli-tests.md
```

### Documentation

- Update relevant `.md` files when changing functionality
- Add examples for new features
- Keep CHANGELOG.md updated

## Code Style

- Follow existing code style in Python and Bash scripts
- Use meaningful variable/function names
- Add comments for complex logic
- Keep functions focused and small

## Types of Contributions

### Bug Fixes
- Describe the bug clearly
- Include steps to reproduce
- Show how your fix resolves it

### New Features
- Explain the use case
- Discuss in issues first (if major)
- Include tests and documentation

### Documentation
- Clarify existing docs
- Fix typos or errors
- Add examples

### Security
- **Report security vulnerabilities privately**
- Email: [SECURITY_CONTACT_EMAIL]
- Do not open public issues for vulnerabilities

## Pull Request Process

1. **Title**: Clear and descriptive
2. **Description**: Explain what and why
3. **Related issues**: Link with `#issue-number`
4. **Tests**: Show test results
5. **Documentation**: List docs updated

## What Happens Next

Maintainers will review your PR within a reasonable time. We may:

- **Merge**: Approved and ready
- **Request changes**: Need revisions
- **Discuss**: Questions or concerns

Be patient and respectful. This is a volunteer-driven project.

## Questions?

- Check existing issues first
- Open a new issue with the `question` label
- Join our community: [COMMUNITY_LINK]

---

**Happy contributing!** 🚀
