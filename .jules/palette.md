## 2024-05-13 - Add Missing Tooltips/ARIA labels to Icon-only buttons
**Learning:** Icon-only buttons in Flutter without the `tooltip` property lack accessible labels for screen readers. It's important to provide `tooltip` as it automatically generates semantic labels for screen readers in Flutter.
**Action:** Consistently add `tooltip` properties to all `IconButton` widgets across the app, especially in heavily used screens like Store Mode and Settings.
