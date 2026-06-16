## 2024-05-24 - Debouncing search fields
**Learning:** Adding debouncers to text search fields prevents unnecessary full rebuilds (like filtering a large history orders list) on every keystroke, improving input responsiveness.
**Action:** When using a `Debouncer` in Flutter, remember to call `_debouncer.cancel()` on actions like clearing the search field, otherwise delayed state updates will overwrite the cleared text.
