
## 2024-07-11 - Server-Side Request Forgery (SSRF) in Webhook Dispatch
**Vulnerability:** The `sendWebhook` function accepted arbitrary URLs and fetched them without validation, exposing the application to SSRF attacks against internal network resources and GCP metadata servers.
**Learning:** Even internal or admin-configured webhook URLs must be strictly validated. The native `URL` class is critical for initial normalization to prevent bypasses, and `redirect: "error"` is required on `fetch` to prevent 3xx redirect bypasses to internal IPs.
**Prevention:** Always implement strict URL validation for outbound requests, blocking internal hostnames/IPs, and enforcing `redirect: "error"` on `fetch` calls handling user-supplied or database-driven URLs.
