## 2024-06-08 - SSRF Vulnerability in Webhook Delivery
**Vulnerability:** A Server-Side Request Forgery (SSRF) vulnerability was found in the `sendWebhook` function in `functions/src/index.ts`. Any signed-in user could create a document in the `webhook_outbox` collection with an arbitrary `targetUrl`, which would be executed blindly by the Cloud Function, potentially allowing access to local metadata or unencrypted network segments.
**Learning:** Security gaps can easily appear in webhooks when user-provided URLs aren't constrained or sanitized before calling `fetch`.
**Prevention:** I modified `sendWebhook` to ensure URL protocol is `https:` and implemented a basic hostname check to block requests to localhost and private IPv4/IPv6 ranges before attempting network calls.
