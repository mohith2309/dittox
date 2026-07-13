## 2024-07-13 - Webhook SSRF Vulnerability
**Vulnerability:** Unrestricted URL fetching in the webhook outbox processor allowed Server-Side Request Forgery (SSRF) by accepting any target URL.
**Learning:** Cloud Function events triggering webhooks must normalize URLs and validate hostnames to prevent access to internal networks or Google Cloud metadata servers, as naive fetch implementations follow harmful redirects.
**Prevention:** Always use the native `URL` class to parse and normalize inputs, explicitly block metadata servers and internal IPv4/IPv6 ranges using strict regex, and enforce `redirect: 'error'` on `fetch` calls.
