## 2024-07-10 - SSRF Vulnerability in Webhook Outbox
**Vulnerability:** Unrestricted Server-Side Request Forgery (SSRF) via `webhook_outbox` Firestore collection. Any authenticated user could create a document with a malicious `targetUrl` to hit internal Google Cloud metadata servers (`169.254.169.254`) or internal IP ranges.
**Learning:** Allowing user-controlled documents to trigger outbound HTTP requests without URL validation or fetch redirect restrictions (`redirect: 'error'`) exposes internal infrastructure.
**Prevention:** Always validate hostnames against a blocklist (internal IPs, metadata server, `.internal` domains) and strictly enforce `redirect: 'error'` in `fetch` calls when processing user-supplied URLs.
