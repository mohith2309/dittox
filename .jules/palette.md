## 2024-06-23 - Custom IconButton Ripple Visibility
**Learning:** Wrapping an `InkWell` around a `Container` with a solid background color obscures the Material ripple effect, breaking visual interaction feedback.
**Action:** Use an `Ink` widget instead of a `Container` for colored backgrounds when creating custom `InkWell` buttons to ensure splash effects render correctly over the background.
