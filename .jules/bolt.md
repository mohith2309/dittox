## 2024-05-19 - [Debounce Search Inputs]
**Learning:** Frequent `setState` calls from `onChanged` events in search fields cause unnecessary and expensive widget tree rebuilds, leading to UI jank, especially when filtering large lists synchronously.
**Action:** Use the existing `Debouncer` utility from `app_optimizations.dart` to delay the `setState` update until the user pauses typing, significantly reducing rebuilds. Ensure `_debouncer.cancel()` is called on explicit actions like clearing the search field to prevent delayed overrides.
