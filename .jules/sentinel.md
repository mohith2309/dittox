## 2025-02-18 - SSRF protection bypasses with native Node.js URL normalization
**Vulnerability:** The webhook dispatcher was vulnerable to Server-Side Request Forgery (SSRF) without URL validation, which could be bypassed by obscure IP encodings if simple string matching was used.
**Learning:** Native `URL` object parsing normalizes obfuscated URLs (e.g. octal IPs like `http://012.0.0.1/`) into standard formats (`10.0.0.1`), meaning a regex only needs to target standard valid forms.
**Prevention:** For robust SSRF mitigation on hostname extraction, always parse with the `URL` API and check `URL.hostname` rather than the raw URL string. Also enforce `redirect: 'error'` on `fetch` calls.
