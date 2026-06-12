## 2024-06-12 - Prevent SSRF via Redirects
**Vulnerability:** Even with URL validation, `fetch` calls can follow redirects, allowing attackers to bypass validation if an external URL redirects to an internal endpoint.
**Learning:** `fetch` in Node.js respects redirects by default. Validating the initial URL does not guarantee safety of the final destination if the external host redirects.
**Prevention:** Always set `redirect: 'error'` in `fetch` options when making outbound webhook requests based on user-provided URLs to prevent bypass.
