## 2024-07-05 - SSRF Vulnerability in Webhook Delivery
**Vulnerability:** The `sendWebhook` function in `functions/src/index.ts` accepts user-provided URLs and passes them directly to `fetch` without any validation.
**Learning:** This exposes the application to Server-Side Request Forgery (SSRF) attacks, allowing an attacker to make the server send HTTP requests to internal IP addresses (like the metadata server or loopback/private network addresses).
**Prevention:** Always parse and validate user-provided URLs before making outbound HTTP requests. Block private IP ranges, loopback addresses, and cloud provider metadata IPs. Additionally, set `redirect: 'error'` in `fetch` to prevent attackers from bypassing SSRF checks via HTTP redirects.
