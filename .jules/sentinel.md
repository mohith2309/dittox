## 2024-06-15 - SSRF Protection with Node.js URL Parser
**Vulnerability:** Server-Side Request Forgery (SSRF) risk in outbound webhook URLs triggered by user-provided data.
**Learning:** To accurately block private/loopback IPs, strict regexes must be used (e.g., `^(?:10\.\d{1,3}\.\d{1,3}\.\d{1,3})$`) to prevent falsely flagging valid domains like `10.example.com`. Furthermore, Node's `URL` parser retains brackets for IPv6 inputs (e.g., `[::1]`), so explicit checks must account for this structure.
**Prevention:** Always use Node's native `URL` parsing to normalize URLs before validation, strictly constrain IPv4 regexes to full string matches, check for bracketed IPv6 addresses, and enforce `redirect: 'error'` in `fetch` to block redirect-based SSRF bypasses.
