## 2024-05-24 - Accessibility for Icon-only Buttons
**Learning:** Icon-only buttons using `FaIcon` inside `InkWell` or `IconButton` lacking explicit labels are entirely skipped or read vaguely by screen readers, making critical actions like "Back" or "Show Password" inaccessible in this app's specific auth flows.
**Action:** Always wrap custom icon-only interactive containers with `Semantics(button: true, label: "...")` and utilize `semanticLabel` in `FaIcon` or `tooltip` properties in standard `IconButton` to ensure screen reader compatibility.
