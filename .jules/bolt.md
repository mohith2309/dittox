## 2024-05-24 - Avoid synchronous setState in text filtering
**Learning:** In Flutter, calling `setState()` synchronously inside a `TextField`'s `onChanged` handler when filtering large lists (e.g., Select Shops or Order History) causes UI jank by blocking the main thread.
**Action:** Use the `Debouncer` class from `lib/utils/app_optimizations.dart` for all search inputs that filter lists. Always ensure `if (mounted)` is checked inside the debouncer callback before calling `setState()` and remember to dispose of the debouncer in `dispose()`.
