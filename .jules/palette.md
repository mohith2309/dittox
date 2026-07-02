
## 2024-07-02 - Ensure Material Ripple Effects are Visible and Add Tooltips
**Learning:** Using a `Container` inside an `InkWell` with a background color hides the Material splash/ripple effect.
**Action:** Replace `Container` with an `Ink` widget when a background color is needed for a custom button, and expose a `tooltip` parameter for accessibility.
