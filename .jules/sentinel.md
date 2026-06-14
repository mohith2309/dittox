
## 2026-06-14 - Fix SSRF in Webhook Outbox
**Vulnerability:** The application was vulnerable to Server-Side Request Forgery (SSRF) when processing webhooks. Users could provide arbitrary URLs via Firestore, which were sent unvalidated `fetch` requests. This allowed potential internal port scanning, accessing loopback addresses, or reaching cloud metadata endpoints.
**Learning:** Outbound webhook invocations in Cloud Functions without strict URL validation and redirect protections provide an open proxy to internal resources.
**Prevention:** Always validate webhook URLs to disallow localhost, private IPv4 ranges, private IPv6 ranges, and common metadata service IPs (e.g., `169.254.169.254`). Enforce `redirect: "error"` on the `fetch` call to prevent redirect-based TOCTOU bypasses.
