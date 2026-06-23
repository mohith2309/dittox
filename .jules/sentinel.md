## 2026-06-23 - SSRF Protection via Native URL Parsing
**Vulnerability:** User-provided webhook URLs in Cloud Functions could target internal resources (SSRF).
**Learning:** Bypassing SSRF filters using obfuscated IP addresses (hex, octal) is a common risk. Native Node.js `URL` object parsing normalizes these formats, preventing obfuscation bypasses.
**Prevention:** Always use Node.js `URL` parsing to normalize URLs before validating against IPv4 blocklists, account for IPv6 brackets `[::1]`, and enforce `redirect: 'error'` in fetch requests to prevent redirect-based bypasses.
