## 2024-11-20 - SSRF Vulnerability in Webhooks
**Vulnerability:** The webhook delivery system `sendWebhook` didn't validate the `targetUrl` before calling `fetch(url, ...)`.
**Learning:** Because URLs weren't validated, an attacker could supply an internal IP address (like `127.0.0.1` or `metadata.google.internal`) or use an external URL that redirects to an internal one via 3xx status codes, thereby achieving a Server-Side Request Forgery (SSRF) to read sensitive metadata or hit internal endpoints.
**Prevention:** Always validate webhook URLs to block internal/loopback IPs and explicitly configure `redirect: 'error'` in fetch options to prevent 3xx bypasses.
