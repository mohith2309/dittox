## 2024-06-26 - Debouncer False Positive Code Review
**Learning:** The `request_code_review` tool may incorrectly flag valid imports of existing local files (like `app_optimizations.dart`) as missing if those files are not included in the patch diff (e.g. they weren't modified in the current branch).
**Action:** Rely on local verification (`flutter test`, `flutter analyze`) rather than `request_code_review` for validating the existence and structure of unchanged local dependencies.
