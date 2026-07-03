## 2024-07-03 - [Debounce Search Inputs]
**Learning:** Synchronous `setState()` calls inside `TextField` `onChanged` handlers that trigger filtering of large lists block the main UI thread and cause jank.
**Action:** Use the `Debouncer` class from `lib/utils/app_optimizations.dart` to debounce search inputs and update state efficiently.
