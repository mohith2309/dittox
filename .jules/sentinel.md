## Initialized
## 2024-05-20 - SSRF Prevention in Webhooks
**Vulnerability:** Webhooks executing user-provided URLs in Cloud Functions could access internal loopback, private IPs, or cloud metadata services.
**Learning:** Cloud functions can inadvertently act as a proxy for internal network enumeration or metadata extraction if URLs aren't strictly validated before `fetch()`. `new URL()` must be used to block obfuscation attempts like `0x7f.0.0.1` or hex/octal encoded IPs.
**Prevention:** Always validate webhook URLs using `URL` parsing, explicitly block loopback, IPv4/IPv6 private ranges, and 169.254.169.254. Add `redirect: "error"` to `fetch` calls to prevent SSRF via HTTP 302 redirects.
