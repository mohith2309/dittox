
## 2024-05-24 - SSRF in Webhook Endpoints
**Vulnerability:** The application was passing unvalidated webhook URLs directly to `fetch`, allowing attackers to send requests to local (e.g., `localhost`, `127.0.0.1`), internal (e.g., `10.x.x.x`), and cloud metadata (`metadata.google.internal`) IPs via Server-Side Request Forgery (SSRF).
**Learning:** `fetch` inherently follows 3xx redirects and resolves internal IPs unless explicitly restricted. Attackers can bypass naive string-matching filters (like `startsWith("127.")` which falsely blocks `127.example.com`) and redirect to internal IPs using HTTP 3xx responses.
**Prevention:** Always validate webhook URLs against strict regexes for IPv4 internal ranges and explicitly block metadata endpoints. Furthermore, when using `fetch` with user-supplied URLs, enforce `redirect: "error"` to block 3xx bypasses.
