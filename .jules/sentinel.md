## 2026-06-21 - Prevent SSRF in Webhook Delivery
**Vulnerability:** External HTTP requests constructed with unvalidated user input via fetch.
**Learning:** Cloud functions making HTTP requests must strictly enforce URL validation to avoid exposing internal metadata services, private IPs, or localhost bypasses.
**Prevention:** Implement an `isSafeUrl` verification with native URL parsing, blocking private subnets and localhost before calling `fetch`.
