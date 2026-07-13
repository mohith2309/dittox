## 2024-05-24 - Server-Side Request Forgery in Webhooks
**Vulnerability:** The `sendWebhook` function fetches arbitrary user-supplied URLs without validation, exposing the application to SSRF attacks targeting internal GCP metadata servers (`169.254.169.254` and `metadata.google.internal`) and private network IPs.
**Learning:** Fetch calls follow HTTP redirects by default, allowing attackers to bypass simple initial URL validation by providing a safe URL that redirects to an internal IP.
**Prevention:** Use the native `URL` class for robust hostname validation, explicitly block metadata IPs/domains, and enforce `redirect: 'error'` in fetch options to prevent redirect-based SSRF bypasses.
