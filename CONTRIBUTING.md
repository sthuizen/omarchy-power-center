# Contributing

Bug reports and focused pull requests are welcome.

## Before opening an issue

- Update Omarchy and reproduce the problem with the latest plugin release.
- Include the Omarchy version, plugin version, battery/power-profile setup,
  relevant shell logs, and exact reproduction steps.
- Remove secrets and personal information from logs.

## Development

Fork the repository, create a short-lived branch, and keep changes scoped.
Preserve Omarchy's native UI components and canonical action commands unless a
change has a documented compatibility reason.

Run before submitting:

```bash
npm test
omarchy plugin validate .
git diff --check
```

Update `CHANGELOG.md` for user-visible changes and `UPSTREAM.md` when importing
new upstream code. By contributing, you agree that your contribution is
licensed under this project's MIT License.
