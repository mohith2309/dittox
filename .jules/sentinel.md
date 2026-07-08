## 2024-07-08 - SSRF in Webhook Delivery
**Vulnerability:** The `sendWebhook` function in `functions/src/index.ts` fetched arbitrary URLs without validation, allowing Server-Side Request Forgery (SSRF) attacks against internal networks or metadata servers.
**Learning:** In Firebase/GCP environments, failing to validate webhook destination URLs or permitting redirects allows attackers to interact with internal infrastructure like `metadata.google.internal` or internal IPs.
**Prevention:** Always parse the URL, block local/internal IP ranges (e.g., 127.x, 10.x, 169.254.x.x), restrict protocols to `http:` and `https:`, and strictly enforce `redirect: "error"` on `fetch` calls.
