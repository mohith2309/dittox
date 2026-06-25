## 2024-06-25 - Debounce map search to prevent unnecessary rebuilds
**Learning:** In Flutter, tying a TextField's `onChanged` directly to `setState` without debouncing can trigger heavy widget tree and list rebuilds on every keystroke, degrading performance, especially in map screens where markers or large lists are regenerated.
**Action:** Use a `Debouncer` from `lib/utils/app_optimizations.dart` to delay the state update until the user finishes typing.
