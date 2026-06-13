## 2024-05-16 - SSRF Protection with Native URL Parsing
**Vulnerability:** User-provided webhook URLs in Firebase Cloud Functions lacked SSRF validation, allowing outbound requests to potentially access internal resources or cloud metadata.
**Learning:** Native `URL` object parsing (`new URL()`) in Node.js automatically normalizes obfuscated IP addresses (like hex or octal encoded IPs), making it a robust foundational layer for URL validation.
**Prevention:** Always use `URL.hostname` for validation and include `redirect: "error"` in the `fetch` options to prevent attackers from bypassing initial checks via HTTP redirects.
