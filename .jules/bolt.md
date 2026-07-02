## 2024-07-02 - Debouncing Search Inputs
**Learning:** Synchronous setState calls inside TextField onChanged handlers that trigger filtering of large lists block the main UI thread and cause jank.
**Action:** Always wrap these updates using the Debouncer class from lib/utils/app_optimizations.dart, and ensure clear buttons cancel the debouncer.
