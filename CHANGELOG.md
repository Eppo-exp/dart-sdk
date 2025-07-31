# Changelog

## 1.2.0

- Support for managing multiple user contexts (anonymous vs logged-in users)
- `Eppo.forSubject()` returns `EppoPrecomputedClient` directly for simpler API
- Added instance management methods: `removeSubject()` and `activeSubjects`

## 1.1.0

- Added Customer-specific routing

## 1.0.2

- Added benchmarks for flag evaluation and configuration fetch

## 1.0.1

- Improved pub.dev metadata to include correct repository and documentation

## 1.0.0

- Initial release
- Core functionality for feature flag evaluation
- Support for string, boolean, integer, numeric, and JSON flag types
- Bandit action evaluation support
- Assignment caching and deduplication
- Precomputed flag evaluation
