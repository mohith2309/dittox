## 2025-02-18 - InkWell vs Container Ripple Effect
**Learning:** In Flutter, placing a colored Container inside an InkWell completely hides the material ripple effect (splash) when the button is tapped, making the button feel dead.
**Action:** Always use an Ink widget for colored backgrounds when an inner InkWell is needed to ensure the material splash/ripple effect remains visible.
