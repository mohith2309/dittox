## 2024-06-25 - SSRF Protection for Webhooks
**Vulnerability:** Server-Side Request Forgery (SSRF) risk in outbound webhooks based on user-provided URLs.
**Learning:** The `sendWebhook` function in Cloud Functions accepted arbitrary URLs and directly invoked them using `fetch`, which could allow attackers to target internal metadata services or private IP ranges.
**Prevention:** When making outbound HTTP requests using user-provided URLs, always parse the URL using the native Node.js `URL` object and validate the hostname to block localhost, private IPv4 addresses, and cloud metadata endpoints. Also, enforce `redirect: 'error'` on the fetch request to prevent redirect-based bypasses.
