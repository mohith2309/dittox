## 2024-06-23 - Prevent SSRF in Webhook Delivery
**Vulnerability:** The `sendWebhook` function in Cloud Functions accepted arbitrary user-controlled URLs without validation and fetched them using default options, allowing Server-Side Request Forgery (SSRF) bypasses where users could target internal services, cloud metadata endpoints, or local network IPs.
**Learning:** Basic regex validation on unparsed URL strings is insufficient because obfuscation (e.g. hex IPs, octal IPs) can bypass it.
**Prevention:** Always parse URLs utilizing native Node.js `URL` object parsing to leverage built-in normalization, apply strict regex patterns for private/internal IPs against `URL.hostname`, and configure HTTP clients to not follow redirects automatically (`redirect: 'error'`).
