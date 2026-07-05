
## 2024-07-05 - Prevent SSRF in Webhooks
**Vulnerability:** Server-Side Request Forgery (SSRF) in `sendWebhook` where arbitrary URLs from Firestore were fetched without validation.
**Learning:** Cloud Functions have access to internal metadata servers (`169.254.169.254`, `metadata.google.internal`) which can leak sensitive tokens and environment variables if not explicitly blocked. Also, standard `fetch` transparently follows redirects, potentially allowing attackers to bypass initial URL validation.
**Prevention:** Always parse URLs, enforce HTTP/HTTPS, explicitly block local/internal IP ranges and metadata hostnames. Critically, enforce `redirect: 'error'` in `fetch` to prevent redirect-based bypasses.
