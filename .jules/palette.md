## 2024-05-19 - Context-Aware IconButton Tooltips
**Learning:** In Flutter, using the `tooltip` property on an `IconButton` correctly sets semantic labels for screen readers. However, when the button's action is context-dependent (like toggling visibility or clearing text in an auth form), the tooltip must also be dynamically assigned to maintain accessibility meaning.
**Action:** Always map the `tooltip` value directly to the state condition that determines the `IconButton`'s action to ensure screen reader context matches visual context.
