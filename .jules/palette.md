## 2024-10-24 - Material Ripple on Custom Colored Buttons
**Learning:** In Flutter, wrapping an `InkWell` around a `Container` with a solid background color completely obscures the Material splash/ripple effect, breaking expected visual feedback for interactive elements.
**Action:** Always use an `Ink` widget to draw colored backgrounds under an `InkWell` to ensure the splash effect remains visible.
