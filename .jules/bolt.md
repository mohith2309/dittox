## 2024-07-25 - Prefer EfficientListView over ListView.builder
**Learning:** The codebase has a custom EfficientListView in lib/utils/app_optimizations.dart that provides optimized list rendering. Standard ListView.builder shouldn't be used directly.
**Action:** Always import and use EfficientListView instead of ListView.builder for better list performance.
