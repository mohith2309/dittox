## 2024-06-20 - Add debouncer to Cart search
**Learning:** Reacting immediately to TextField onChanged events without a debouncer can cause significant UI jank when the list filtering logic is expensive (e.g. iterating and matching text over hundreds of items), especially in Flutter where it causes redundant widget rebuilds.
**Action:** Use the existing `Debouncer` from `app_optimizations.dart` to throttle `onChanged` events, and remember to `cancel()` it before explicit manual clears or chip selections to prevent race conditions where the debounced event overrides the manual action.
