function isSafeUrl(urlStr) {
  try {
    const parsedUrl = new URL(urlStr);
    const hostname = parsedUrl.hostname;

    // Block internal GCP metadata server
    if (hostname === "metadata.google.internal" || hostname.endsWith(".internal")) {
      return false;
    }

    // Block localhost, private IPs and metadata IPs
    const isLocalhost = /^localhost$/i.test(hostname) || /^127\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(hostname) || hostname === "[::1]";
    const isMetadata = /^169\.254\.169\.254$/.test(hostname);
    const isPrivateIPv4 = /^(10\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3})$/.test(hostname);

    if (isLocalhost || isMetadata || isPrivateIPv4) {
      return false;
    }

    // Only allow http/https protocols
    if (parsedUrl.protocol !== "http:" && parsedUrl.protocol !== "https:") {
      return false;
    }

    return true;
  } catch (e) {
    return false;
  }
}
console.log(isSafeUrl("http://169.254.169.254"));
console.log(isSafeUrl("https://metadata.google.internal"));
console.log(isSafeUrl("http://10.0.0.1"));
console.log(isSafeUrl("https://example.com"));
