## 2024-05-30 - SSRF Vulnerability in Webhook Processing
**Vulnerability:** `sendWebhook` used `fetch` directly with user-controlled URLs, allowing SSRF attacks targeting internal IPs and GCP metadata.
**Learning:** In Google Cloud functions, `fetch` without restrictions can access sensitive internal endpoints like `169.254.169.254` or `metadata.google.internal` and also follow 3xx redirects to internal infrastructure.
**Prevention:** Always validate hostnames strictly against internal IP ranges/metadata URLs, use exact regex matching for IPs, explicitly block GCP metadata servers, and set `redirect: 'error'` on fetch to prevent redirect bypasses.
