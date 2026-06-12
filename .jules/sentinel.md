## 2024-05-24 - Preventing SSRF in Cloud Functions Webhooks
**Vulnerability:** Server-Side Request Forgery (SSRF) allowed attackers to make Cloud Functions send HTTP requests to internal networks (localhost, private IPs) or cloud metadata endpoints.
**Learning:** When using Node.js `URL.hostname` for validation, regexes must strictly match IPv4 structures (e.g., `^(?:10\.\d...)$`) and account for IPv6 addresses being wrapped in brackets (e.g., `[::1]`) to avoid bypassing filters or falsely flagging valid domains like `10.example.com`.
**Prevention:** Always validate user-provided URLs before making outbound HTTP requests. Block localhost, private IPs, and metadata endpoints. Also enforce `redirect: 'error'` on requests like `fetch` to prevent redirect-based SSRF bypasses.
