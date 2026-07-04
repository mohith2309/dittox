## 2024-07-04 - Server-Side Request Forgery (SSRF) Protection in Webhooks
**Vulnerability:** The application was vulnerable to SSRF in webhook delivery functionality, allowing attackers to potentially access internal resources via unvalidated URLs and HTTP redirects.
**Learning:** Native `fetch` behavior automatically follows redirects, which can bypass initial URL validation. Enforcing `redirect: 'error'` is critical to prevent attackers from using 3xx redirects to access internal IPs, even if it might break endpoints relying on harmless HTTP-to-HTTPS redirects.
**Prevention:** Use native Node.js `URL` parsing, explicitly block private/reserved IP ranges using strict regexes, and always set `redirect: 'error'` in `fetch` calls handling external URLs.
