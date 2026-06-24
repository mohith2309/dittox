## 2024-06-24 - Prevent SSRF in Webhooks
**Vulnerability:** The application was making outbound HTTP requests (webhooks) from Cloud Functions based on user-provided URLs without validating the target URL. This could lead to Server-Side Request Forgery (SSRF).
**Learning:** We must properly validate URL hostnames using Node.js `URL` built-in object to proactively block requests to internal networks, localhost, metadata endpoints (e.g., `169.254.169.254`), private IP ranges, and IPv6 representations.
**Prevention:** Use the `URL` parser and enforce `redirect: 'error'`. Regexes must ensure full hostname matches (e.g., using `^...$`) to avoid substring bypasses.
