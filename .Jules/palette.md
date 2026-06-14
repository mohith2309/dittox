## 2024-05-18 - InkWell Splash Visibility
**Learning:** Using `Container` with a background color inside an `InkWell` obscures the Material ripple/splash effect, leading to a loss of interactive visual feedback.
**Action:** Always use an `Ink` widget instead of a `Container` for colored backgrounds when nested inside an `InkWell` or `GestureDetector` where Material touch feedback is desired. Also provide `borderRadius` to the `InkWell` to ensure the splash doesn't bleed outside the `Ink` bounds.
