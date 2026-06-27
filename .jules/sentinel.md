
## 2024-05-28 - SSRF Prevention in Node.js Webhooks
**Vulnerability:** External webhook fetching logic failed to validate user-supplied URLs, potentially allowing requests to loopback addresses, metadata IPs, and private networks (Server-Side Request Forgery).
**Learning:** Node.js native `fetch` combined with unstructured data can inadvertently access cloud metadata or local environments. Custom URL validation requires strict parsing logic that handles IPv6 loopback addresses and properly anchors regex to avoid bypassing with malformed valid subdomains (e.g. `10.example.com`).
**Prevention:** Always parse URLs via the native `URL` class to ensure consistent structural understanding. Explicitly restrict the target protocol to `http/https`, ensure regex strings are strict (using anchors ^ and $), block known sensitive hostnames directly, and set `redirect: "error"` in the fetch options to mitigate malicious redirection chains.
