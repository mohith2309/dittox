## 2024-07-01 - Flutter IconButton Semantic Labels
**Learning:** In Flutter, icon-only buttons lack accessibility context for screen readers by default. The `tooltip` property natively doubles as the accessibility semantic label for `IconButton` widgets.
**Action:** Always provide a `tooltip` string for any `IconButton` to simultaneously support sighted users (hover states) and users relying on assistive technology (semantic labels).
