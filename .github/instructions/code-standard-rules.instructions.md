# LIVE LOCATION PLUGIN -- AGENT CODE RULES

## Purpose

This document defines strict implementation rules for AGENT when
generating, refactoring, or modifying the Live Location Flutter plugin.

The objective is to ensure enterprise-grade quality, strict architecture
discipline, high performance, and zero-compromise engineering standards.

AGENT must follow all constraints without exception.

------------------------------------------------------------------------

# 1. Core Engineering Principles

1.  Follow SOLID principles strictly.
2.  No architectural shortcuts.
3.  No implicit behavior --- everything must be explicit.
4.  No hidden state.
5.  No global mutable variables.
6.  No silent failures.
7.  All public APIs must include complete dartdoc documentation.
8.  All configuration objects must be immutable.
9.  Prefer clarity over cleverness.
10. Performance and memory safety are mandatory.

------------------------------------------------------------------------

# 2. Architectural Constraints

## 2.1 Layer Separation (Strict)

AGENT must enforce clear separation between:

-   Dart Public API Layer
-   Platform Channel Layer
-   Native Android Implementation
-   Native iOS Implementation

No cross-layer leakage of responsibilities.

Business logic must never be placed inside: - MethodChannel handlers -
EventChannel handlers - Native callback delegates

------------------------------------------------------------------------

# 3. Initialization Rules

1.  Plugin must use lazy singleton initialization.
2.  Double initialization must throw a structured exception.
3.  Configuration must be validated immediately.
4.  Initialization must fail fast on invalid input.
5.  No nullable configuration fields.

------------------------------------------------------------------------

# 4. Stream & Event Handling Rules

1.  Use broadcast StreamController.
2.  Never emit null values.
3.  Cache last known location.
4.  Prevent duplicate native listeners.
5.  Stream must properly handle onListen and onCancel.
6.  Stream must close during dispose.
7.  Native must stop emitting when Dart cancels subscription.

------------------------------------------------------------------------

# 5. Permission Handling Rules

1.  No tracking without explicit permission.
2.  Must expose:
    -   checkPermission()
    -   requestPermission()
3.  Must map platform permission states to Dart enum.
4.  Must throw structured exception if permission invalid.
5.  No automatic permission escalation.

------------------------------------------------------------------------

# 6. Android Implementation Rules

1.  Use FusedLocationProviderClient.
2.  Foreground Service required for background tracking.
3.  Create NotificationChannel for Android 8+.
4.  Remove location updates in onDestroy().
5.  Handle Android 10+ background permission separately.
6.  Handle Android 13+ notification permission.
7.  No deprecated APIs.
8.  Target latest stable Android SDK.
9.  No memory leaks in Service or callbacks.
10. Avoid unnecessary object allocation inside location callback.

------------------------------------------------------------------------

# 7. iOS Implementation Rules

1.  Use CLLocationManager.
2.  Avoid retain cycles in delegate.
3.  Set allowsBackgroundLocationUpdates only if configured.
4.  Support significant location change mode (if enabled).
5.  Handle Always permission properly.
6.  Stop updates immediately on dispose.
7.  Follow Apple privacy guidelines strictly.

------------------------------------------------------------------------

# 8. Performance Rules

1.  No polling mechanisms.
2.  No heavy computation on main thread.
3.  Avoid repeated MethodChannel calls.
4.  Reuse native request objects.
5.  Support configurable interval and distance filter.
6.  Avoid highest accuracy unless explicitly requested.
7.  No logging in release mode.
8.  No background isolate unless strictly required.

------------------------------------------------------------------------

# 9. Error Handling Standards

AGENT must define and use structured exceptions:

-   LocationPermissionException
-   LocationServiceDisabledException
-   LocationInitializationException
-   PlatformNotSupportedException

Rules:

1.  Never return null for error states.
2.  Never swallow platform exceptions.
3.  Map native exceptions into Dart exceptions explicitly.
4.  Include meaningful error messages.

------------------------------------------------------------------------

# 10. Documentation Enforcement

AGENT must ensure the repository includes:

-   README.md
-   ARCHITECTURE.md
-   ANDROID_SETUP.md
-   IOS_SETUP.md
-   BACKGROUND_BEHAVIOR.md
-   API_REFERENCE.md
-   SECURITY.md
-   PERFORMANCE_GUIDELINES.md
-   CHANGELOG.md
-   CONTRIBUTING.md

Every public class, method, and enum must include full dartdoc.

------------------------------------------------------------------------

# 11. Code Quality & Linting

1.  Strict null-safety.
2.  Zero analyzer warnings.
3.  No unused imports.
4.  No dead code.
5.  No TODO comments in production commits.
6.  Enforce flutter_lints + strict custom lints.
7.  Follow official Flutter plugin structure.
8.  Unit tests for Dart logic where possible.

------------------------------------------------------------------------

# 12. Security & Privacy Rules

1.  Do not store location data.
2.  Do not log raw location in release builds.
3.  Do not send network requests from plugin.
4.  Do not include analytics.
5.  Respect platform privacy guidelines fully.

------------------------------------------------------------------------

# 13. Release Standards

1.  Semantic versioning required.
2.  Update CHANGELOG.md on every release.
3.  Example app must demonstrate:
    -   Initialization
    -   Permission flow
    -   Foreground tracking
    -   Background tracking
    -   Proper disposal
4.  Plugin must build in release mode for Android and iOS.
5.  Plugin must pass analyze with zero warnings.

------------------------------------------------------------------------

AGENT must prioritize architectural integrity, memory safety, and
long-term maintainability over rapid generation.

End of AGENT Code Rules.
