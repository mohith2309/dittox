## 2024-06-13 - Accessible CustomIconButtons

**Learning:** When making custom icon buttons in Flutter, using a `Container` with `BoxDecoration` over an `InkWell` obscures the material ripple effect and misses out on standard accessibility semantics. Furthermore, these custom icon buttons lack standard `Tooltip` and `Semantics` which makes screen readers struggle with icon-only buttons.
**Action:** Always prefer `Ink` + `InkWell` combined over `Container` for round buttons, and wrap icon-only buttons with `Tooltip` and `Semantics(button: true, label: "...")` so they provide correct visual feedback and are fully accessible.
