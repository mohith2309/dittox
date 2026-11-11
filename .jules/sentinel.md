## 2024-03-24 - SSRF in Webhook Delivery
**Vulnerability:** User-supplied webhook URLs were fetched directly using `fetch` without validating the destination host or restricting protocols.
**Learning:** This allowed attackers to specify internal IP addresses or GCP metadata servers (e.g., `169.254.169.254`, `metadata.google.internal`), leading to Server-Side Request Forgery (SSRF) and potential leakage of internal metadata or access tokens.
**Prevention:** Always parse and validate user-supplied URLs to block non-HTTP protocols, internal IP ranges, localhost, and metadata servers. Enforce `redirect: 'error'` on `fetch` calls to prevent bypassing the validation via HTTP redirects.
