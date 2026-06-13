## 2024-05-30 - Debouncing text search to prevent large UI re-renders
**Learning:** Using synchronous `setState` in text inputs with complex list rendering (e.g. `onChanged: (val) => setState(...)`) causes noticeable jank and battery drain in Flutter since the entire list re-evaluates.
**Action:** Always wrap text-based search/filter state changes inside a `Debouncer` class (available in `lib/utils/app_optimizations.dart`), especially for data-heavy views like Cart and History Screens.
