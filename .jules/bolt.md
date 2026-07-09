## 2024-07-09 - Debounce Search Filters
**Learning:** Synchronous setState() calls inside TextField onChanged handlers that trigger filtering of large lists cause jank by blocking the main thread.
**Action:** Always wrap these updates using the Debouncer class from lib/utils/app_optimizations.dart to ensure smooth UI performance.
