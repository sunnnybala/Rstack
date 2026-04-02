# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in RStack, please report it responsibly.

**Do NOT open a public GitHub issue for security vulnerabilities.**

Instead, email **dhruvagarwal5018@gmail.com** with:

1. Description of the vulnerability
2. Steps to reproduce
3. Potential impact
4. Suggested fix (if any)

We will acknowledge your report within 48 hours and aim to release a fix within 7 days for critical issues.

## Scope

RStack is a set of SKILL.md files and bash scripts. Security concerns include:

- **Command injection** in bash scripts (`bin/rstack-config`, `bin/rstack-preflight`, etc.)
- **Credential exposure** in config files or skill outputs
- **Unsafe Modal commands** that could affect cloud resources
- **Path traversal** in file operations

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x   | Yes       |

## Best Practices for Contributors

- Never commit API keys, tokens, or credentials
- Use `~/.modal.toml` and native auth stores for credentials
- Validate all user input in bash scripts
- Use `set -euo pipefail` in all scripts
