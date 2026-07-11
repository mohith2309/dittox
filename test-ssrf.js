const urls = [
  "http://127.0.0.1/admin",
  "http://127.example.com",
  "http://169.254.169.254/computeMetadata/v1",
  "https://metadata.google.internal",
  "http://[::1]/",
  "https://example.com",
  "https://international-bank.com",
  "http://10.0.0.1",
  "http://192.168.1.1",
  "http://172.16.0.1"
];

for (const url of urls) {
  try {
    const parsedUrl = new URL(url);
    const hostname = parsedUrl.hostname;

    if (hostname === "metadata.google.internal" || hostname.endsWith(".internal")) {
      console.log(`BLOCKED: ${url} (internal hostname)`);
      continue;
    }

    const isLocalhost = /^localhost$/i.test(hostname) || /^127\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(hostname) || hostname === "[::1]";
    const isMetadata = /^169\.254\.169\.254$/.test(hostname);
    const isPrivateIPv4 = /^(10\.\d{1,3}\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2[0-9]|3[0-1])\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3})$/.test(hostname);

    if (isLocalhost || isMetadata || isPrivateIPv4) {
      console.log(`BLOCKED: ${url} (internal IP)`);
      continue;
    }

    console.log(`ALLOWED: ${url}`);
  } catch (e) {
    console.log(`INVALID: ${url}`);
  }
}
