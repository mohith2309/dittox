## 2024-11-11 - SSRF Prevention in Node.js Webhooks
**Vulnerability:** Server-Side Request Forgery (SSRF) in webhook delivery allowing attackers to access internal Google Cloud metadata servers or local networks.
**Learning:** `fetch` inherently follows redirects and doesn't block internal IPs. User-provided URLs for webhooks must be strictly validated against internal ranges before execution.
**Prevention:** Always parse URLs using the `URL` class, validate hostnames against an explicitly blocked list of internal IPs/domains (including metadata servers and IPv6 localhost), and strictly enforce `redirect: 'error'` on `fetch` calls to prevent 3xx bypasses.
