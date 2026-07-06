## 2024-05-14 - SSRF in Webhook Delivery
**Vulnerability:** User-provided webhook URLs were directly fetched without validation, allowing SSRF attacks targeting internal GCP metadata servers and localhost.
**Learning:** Even internal queue processors must validate outbound URLs when the target is user-defined, and fetch requests must disable redirects (`redirect: "error"`) to prevent bypasses.
**Prevention:** Always implement strict URL hostname validation against known internal IP ranges and metadata servers before making outbound HTTP requests, and disable redirects.
