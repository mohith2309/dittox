## 2026-06-29 - Prevent SSRF in Webhook Dispatcher
**Vulnerability:** Unvalidated user-provided URLs in webhook dispatcher allowed Server-Side Request Forgery (SSRF) against internal metadata/private IPs.
**Learning:** When making outbound HTTP requests from Cloud Functions based on user-provided URLs, always prevent SSRF by validating URLs.
**Prevention:** Utilize native Node.js URL parsing to check hostnames against private/metadata IP ranges, and enforce redirect: 'error' in fetch.
