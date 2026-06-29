## 2024-06-29 - Fixed SSRF in Webhook delivery
**Vulnerability:** Unrestricted webhook URLs could allow attackers to access internal network resources or cloud metadata via SSRF.
**Learning:** Relying on native URL validation with `URL.hostname` allows detecting non-standard formatting of private IPs, but redirects must also be disabled (`redirect: "error"`) to prevent bypassing DNS checks.
**Prevention:** Always parse outbound user-controlled URLs and validate the exact hostname against a strict allowlist or denylist of private/metadata IP ranges, and enforce redirect blocks on `fetch` calls.
