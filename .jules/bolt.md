## 2024-05-14 - Search Input Debouncing for Large Lists
**Learning:** Synchronous state updates (`setState`) in `TextField` `onChanged` handlers that trigger filtering of large lists (like Order History or Select Shops) can block the main UI thread, causing jank and lagging during rapid typing.
**Action:** Always wrap these state updates using the `Debouncer` class from `lib/utils/app_optimizations.dart`, and ensure `_debouncer.dispose()` is called in the widget's `dispose()` method to prevent memory leaks.
