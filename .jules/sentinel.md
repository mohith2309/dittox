## 2024-07-02 - SSRF in Webhook Functions
**Vulnerability:** User-controlled webhook URLs in Cloud Functions were requested without validation, allowing Server-Side Request Forgery (SSRF) against internal resources (like metadata servers, localhost, private IPs).
**Learning:** Using native Node.js `URL` object parsing with strict IPv4 regexes (instead of string `startsWith()`) is essential for robust SSRF protection, preventing hex/octal obfuscation bypasses while avoiding false positives on domains like `127.example.com`.
**Prevention:** Always parse untrusted URLs using `URL`, validate the `hostname` against strict blocklists (loopback, private IPs, metadata), and enforce `redirect: 'error'` on `fetch` calls.
