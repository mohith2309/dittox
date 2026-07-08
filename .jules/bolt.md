## 2024-10-24 - Debouncing TextField onChanged in Large Lists
**Learning:** Synchronous `setState()` calls inside `TextField` `onChanged` handlers that trigger filtering of large lists (like Order History or Select Shops) block the main UI thread and cause jank.
**Action:** Always wrap these state updates using the `Debouncer` class from `lib/utils/app_optimizations.dart`, and remember to call `dispose()` on the debouncer to prevent memory leaks.
