## 2024-05-18 - Prevent Server-Side Request Forgery in Webhooks
**Vulnerability:** The outbound webhook function passed user-controlled URLs directly to `fetch()` without preventing internal network access.
**Learning:** `fetch()` defaults to following redirects. An attacker can set a webhook URL to `http://evil.com/redirect`, which redirects to `http://169.254.169.254` (cloud metadata), bypassing initial regex validation if redirects aren't disabled.
**Prevention:** Always use a combination of strict native URL parsing/regex validation for the initial URL *and* set `redirect: "error"` in the fetch config.
