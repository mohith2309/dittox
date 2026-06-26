## 2024-05-24 - Prevent SSRF in Webhook Delivery
**Vulnerability:** User-provided webhook URLs could be exploited to make requests to internal network addresses or cloud metadata endpoints (SSRF).
**Learning:** Validating URLs before making outbound requests using native URL parsing is crucial to prevent obfuscation bypasses (like hex/octal encoded IPs).
**Prevention:** Enforce strict allowlists for protocols, block private IP ranges and localhost, and set redirect to 'error' to prevent open redirect bypasses.
