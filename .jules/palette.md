## 2024-06-25 - CustomIconButton Accessibility and Interaction Polish
**Learning:** In Flutter, adding a `tooltip` property to custom icon buttons automatically provides semantic labels for screen readers, enhancing accessibility. Additionally, when using `InkWell` for tap effects, using `Container` with a background color obscures the ripple effect.
**Action:** Always wrap custom icon buttons in a `Tooltip` if a label is provided, and use `Ink` instead of `Container` for background colors to preserve the material splash/ripple effect.
