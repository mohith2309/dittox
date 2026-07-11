## 2024-05-14 - Optimize Search Filtering with Debouncing
**Learning:** Synchronous `setState()` calls inside `TextField` `onChanged` handlers that trigger filtering of large lists (like Order History or Cart) cause the main UI thread to block, leading to jank and dropped frames, especially on slower devices or with large data sets.
**Action:** Always wrap these updates using the `Debouncer` class from `lib/utils/app_optimizations.dart`. Ensure `_debouncer.dispose()` is called in the widget's `dispose()` method to prevent memory leaks.
