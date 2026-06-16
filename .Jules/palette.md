## 2024-05-18 - InkWell Splash Effect Fix
**Learning:** Using `Container` inside an `InkWell` with a background color obscures the Material ripple (splash) effect.
**Action:** Always use an `Ink` widget instead of `Container` when applying a background color to a child of an `InkWell` to preserve visual touch feedback.
