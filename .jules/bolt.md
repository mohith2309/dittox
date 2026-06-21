## 2024-11-21 - Debouncing Text Inputs
**Learning:** In Flutter, updating state synchronously on every keystroke (`onChanged`) for a search `TextField` can cause excessive full-widget-tree rebuilds, leading to significant UI jank when typing.
**Action:** Always wrap text input `onChanged` handlers in a `Debouncer` to batch state updates. Additionally, remember to explicitly cancel the debouncer (`_debouncer.cancel()`) when performing direct UI actions (like clicking a 'clear' or 'recent search' button) to prevent the delayed callback from overriding the synchronous update.
