## 2024-06-30 - Search Filter Optimizations
**Learning:** In a heavily data-driven app like this, synchronous `setState()` on every keystroke for filtering long lists (like Order History or Select Shops) can block the main UI thread and cause jank.
**Action:** The `Debouncer` class in `lib/utils/app_optimizations.dart` should be used consistently to wrap all `onChanged` search input handlers that trigger re-computations of large filtered lists.
