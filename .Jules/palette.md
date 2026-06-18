## 2024-05-18 - First entry

## 2024-06-18 - InkWell vs Container background in Flutter
**Learning:** In Flutter, if an `InkWell` (which provides the Material ripple effect on tap) has a `Container` child with a non-transparent background color (or decoration with color), the `Container` will paint over and visually obscure the ripple effect.
**Action:** When creating custom buttons with `InkWell` that need a colored background, use an `Ink` widget instead of a `Container` to ensure the material splash/ripple effect is drawn correctly above the background color.
