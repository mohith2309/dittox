## 2024-06-24 - SSRF Vulnerability in Webhook Processing
**Vulnerability:** The application was making outbound HTTP requests via `fetch` using user-provided URLs without validating the destination, exposing it to Server-Side Request Forgery (SSRF).
**Learning:** Native Node.js `URL` parsing is critical for SSRF protection because it normalizes obfuscated IP addresses (like hex or octal representations) into standard dotted-decimal formats, making validation reliable.
**Prevention:** Always validate parsed `URL.hostname` against private IP ranges and cloud metadata endpoints (e.g., `169.254.169.254`) and enforce `redirect: 'error'` on outbound `fetch` calls.
