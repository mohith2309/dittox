## 2025-02-14 - Fix Server-Side Request Forgery (SSRF) in Firebase Cloud Functions webhooks
**Vulnerability:** The webhook dispatcher inside the Firebase Cloud Function passed user-provided URLs to `fetch()` without validating the target domains.
**Learning:** Functions meant to dispatch HTTP requests out of the local network must validate the URL hostnames natively to ensure requests don't hit loopback, private IPs, or cloud provider metadata endpoints. Using Node's native `URL` class handles host normalization which prevents simple bypasses.
**Prevention:** Always implement an `isSafeUrl()` validation before executing outbound HTTP requests when relying on URLs provided by or stored in the database. Ensure `fetch()` sets `redirect: 'error'` to avoid redirect-based SSRF.
