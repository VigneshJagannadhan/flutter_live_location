# Contributing to live_location

Thank you for taking the time to contribute! Every bug report, feature suggestion, and pull
request makes this plugin better for everyone.

---

## Table of Contents

1. [Code of Conduct](#code-of-conduct)
2. [Reporting Bugs](#reporting-bugs)
3. [Requesting Features](#requesting-features)
4. [Development Setup](#development-setup)
5. [Making Changes](#making-changes)
6. [Code Standards](#code-standards)
7. [Testing](#testing)
8. [Submitting a Pull Request](#submitting-a-pull-request)
9. [Commit Message Guidelines](#commit-message-guidelines)

---

## Code of Conduct

Be respectful and constructive. This is an open-source project maintained in spare time.
Rude, dismissive, or harassing behaviour will result in your contribution being closed
without review.

---

## Reporting Bugs

1. Check the [existing issues](https://github.com/VigneshJagannadhan/flutter_live_location/issues)
   to make sure the bug has not already been reported.
2. Open a new issue and include:
   - A clear title describing the problem.
   - Steps to reproduce, ideally a minimal code snippet.
   - What you expected to happen vs. what actually happened.
   - Your Flutter and Dart SDK versions (`flutter --version`).
   - The platform (Android / iOS), OS version, and physical device or simulator.
   - Relevant log output (with any sensitive data removed).

---

## Requesting Features

1. Check [existing issues](https://github.com/VigneshJagannadhan/flutter_live_location/issues) and
   [open pull requests](https://github.com/VigneshJagannadhan/flutter_live_location/pulls) first.
2. Open an issue labelled **enhancement** and describe:
   - The problem you are trying to solve.
   - Your proposed solution or API design.
   - Any alternative approaches you considered.

Feature requests are evaluated against the plugin's goal of staying minimal, focused, and
easy to use. Large scope changes will be discussed before any implementation begins.

---

## Development Setup

### Prerequisites

| Tool | Minimum version |
|---|---|
| Flutter | 3.3.0 |
| Dart SDK | 3.10.8 |
| Android Studio | Latest stable |
| Xcode | Latest stable (macOS only) |

### Clone and install

```bash
git clone https://github.com/VigneshJagannadhan/flutter_live_location.git
cd live_location
flutter pub get
cd example && flutter pub get && cd ..
```

### Run the example app

```bash
cd example
flutter run
```

### Run all tests

```bash
flutter test
```

---

## Making Changes

1. **Fork** the repository and create a branch from `main`:

   ```bash
   git checkout -b fix/your-bug-description
   # or
   git checkout -b feat/your-feature-name
   ```

2. Keep your branch focused — one bug fix or one feature per pull request.

3. Do not mix refactoring with functional changes in the same PR.

4. Update `CHANGELOG.md` with a short entry under `## Unreleased`.

---

## Code Standards

This project follows strict quality rules. Your contribution must meet all of the
following before it will be merged.

### Dart

- **Null safety** — all code must be fully null-safe.
- **No analyzer warnings** — run `flutter analyze` and fix every issue.
- **No unused imports** — remove them.
- **No TODO comments** — resolve the problem before submitting.
- **Dartdoc on all public APIs** — every public class, method, and enum must have a
  doc comment.
- Follow the existing code style (2-space indentation, trailing commas, etc.).

### Architecture

- Keep strict separation between layers: Dart API → Platform Interface → MethodChannel
  → Native.
- Business logic must not live inside MethodChannel or EventChannel handlers.
- No global mutable state.
- Configuration objects must be immutable (`final` fields, `const` constructors where
  possible).

### Native (Android — Kotlin)

- Target the latest stable Android SDK.
- No deprecated APIs.
- Remove location updates in `onDestroy()`.
- No memory leaks in Service or callbacks.

### Native (iOS — Swift)

- Avoid retain cycles — use `[weak self]` in closures.
- Stop updates immediately in `dispose`.
- Follow Apple's privacy guidelines.

### Security & Privacy

- Do not store location data.
- Do not log raw coordinates in release builds.
- Do not add network requests to the plugin.
- Do not include analytics or tracking of any kind.

---

## Testing

All changes must include tests. Run the full suite before opening a PR:

```bash
flutter test
```

Rules:
- Bug fixes must include a test that would have caught the bug.
- New features must include tests covering the happy path and at least one error case.
- Do not delete or weaken existing tests.
- Use `MockPlatformInterfaceMixin` for platform mocking — never spin up a real device
  in unit tests.

---

## Submitting a Pull Request

1. Ensure `flutter analyze` passes with **zero** issues.
2. Ensure `flutter test` passes with **zero** failures.
3. Ensure `flutter pub publish --dry-run` passes with **zero** warnings.
4. Open a pull request against the `main` branch.
5. Fill in the PR template completely:
   - What problem does this solve?
   - What was changed and why?
   - How was it tested?
   - Screenshots or logs if relevant.

Pull requests that fail analysis, fail tests, or do not include a description will be
closed without review.

---

## Commit Message Guidelines

Use the following format:

```
<type>: <short summary in present tense, max 72 chars>
```

| Type | Use when |
|---|---|
| `feat` | Adding a new feature |
| `fix` | Fixing a bug |
| `test` | Adding or updating tests |
| `docs` | Documentation changes only |
| `refactor` | Code restructuring with no behaviour change |
| `chore` | Build process, dependency updates, tooling |

**Examples:**

```
feat: add distanceTo helper on LocationUpdate
fix: stop foreground service on dispose when background disabled
test: add permission denied stream state tests
docs: update iOS background mode setup steps
```

---

## Questions?

Open a [GitHub Discussion](https://github.com/VigneshJagannadhan/flutter_live_location/discussions)
or file an issue labelled **question**.

---

*Maintained by [Vignesh Jagannadhan (Vignesh K)](https://github.com/VigneshJagannadhan).*
