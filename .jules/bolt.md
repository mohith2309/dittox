## 2023-10-27 - Unintentional Lockfile Modifications
**Learning:** Running `flutter test` or `flutter pub get` can unintentionally downgrade or modify lockfiles like `pubspec.lock` depending on the environment SDK version, which clutters PRs with unrelated, risky changes.
**Action:** Always run `git status` after tests or analysis, and explicitly use `git restore --staged pubspec.lock && git restore pubspec.lock` (or equivalent for other package managers) to revert any unintended lockfile modifications before creating a PR.
