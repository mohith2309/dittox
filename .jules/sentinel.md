## 2024-06-20 - Webhook SSRF Vulnerability Prevention
**Vulnerability:** The `sendWebhook` function accepted arbitrary user-provided URLs without validation, leading to a Server-Side Request Forgery (SSRF) risk.
**Learning:** Even internal helper functions need strict input validation if they act on user-controlled inputs downstream (e.g., webhook configurations).
**Prevention:** Implement strict URL validation to block loopback addresses (`127.0.0.1`), private networks (`10.x.x.x`), and cloud metadata IP addresses (`169.254.169.254`). Always enforce `redirect: "error"` in outbound requests to prevent redirect-based bypasses.
