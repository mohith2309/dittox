const firebaseConfig = {
  apiKey: "AIzaSyDNldKXE9Lv42jWEq2H8JfBLwczfr19dtg",
  authDomain: "dittoc-5a839.firebaseapp.com",
  projectId: "dittoc-5a839",
  storageBucket: "dittoc-5a839.firebasestorage.app",
  messagingSenderId: "374206849691",
  appId: "1:374206849691:web:53dd4dae9b7fb2a841dc3e",
  measurementId: "G-JY1CS7Y989",
};

const firebase = {
  auth: null,
  db: null,
  googleProvider: null,
  createUserWithEmailAndPassword: null,
  signInWithEmailAndPassword: null,
  signInWithPopup: null,
  signOut: null,
  collection: null,
  getDocs: null,
  limit: null,
  orderBy: null,
  query: null,
  where: null,
};

const root = document.querySelector("#app");
const state = {
  user: null,
  authReady: false,
  appTab: "upload",
  selectedFile: null,
  shops: [],
  orders: [],
  toastTimer: null,
  firebaseError: "",
};

const services = [
  ["Document prints", "PDF, notes, forms, assignments, resumes, and booklets with page range control."],
  ["Store discovery", "Find print shops by distance, availability, ratings, and basic price preview."],
  ["Order tracking", "Track uploaded, accepted, printing, ready, collected, and past order states."],
];

const fallbackShops = [
  { name: "Campus Print Hub", address: "1.4 km away", avgRating: 4.7, status: "Open" },
  { name: "Quick Xerox Point", address: "2.1 km away", avgRating: 4.5, status: "Open" },
  { name: "Dittox Partner Store", address: "3.0 km away", avgRating: 4.8, status: "Busy" },
];

const fallbackOrders = [
  { id: "ORD-1042", title: "Course_notes.pdf", status: "Ready", amount: "Rs 84" },
  { id: "ORD-1041", title: "Project_report.pdf", status: "Printing", amount: "Rs 126" },
  { id: "ORD-1039", title: "Hall_ticket.pdf", status: "Collected", amount: "Rs 12" },
];

function route() {
  const path = window.location.pathname.toLowerCase();
  if (path.startsWith("/app")) return "app";
  if (path.startsWith("/store")) return "store";
  return "home";
}

async function clearOldFlutterServiceWorker() {
  try {
    const reloadKey = "dittox-static-site-cache-reset-v1";
    const hadController = "serviceWorker" in navigator && navigator.serviceWorker.controller;
    if ("serviceWorker" in navigator) {
      const registrations = await navigator.serviceWorker.getRegistrations();
      await Promise.all(registrations.map((registration) => registration.unregister()));
    }
    if ("caches" in window) {
      const keys = await caches.keys();
      await Promise.all(keys.map((key) => caches.delete(key)));
    }
    if (hadController && sessionStorage.getItem(reloadKey) !== "true") {
      sessionStorage.setItem(reloadKey, "true");
      window.location.reload();
    }
  } catch (_) {}
}

async function initFirebase() {
  try {
    const [appModule, authModule, firestoreModule] = await Promise.all([
      import("https://www.gstatic.com/firebasejs/10.12.5/firebase-app.js"),
      import("https://www.gstatic.com/firebasejs/10.12.5/firebase-auth.js"),
      import("https://www.gstatic.com/firebasejs/10.12.5/firebase-firestore.js"),
    ]);

    const firebaseApp = appModule.initializeApp(firebaseConfig);
    firebase.auth = authModule.getAuth(firebaseApp);
    firebase.db = firestoreModule.getFirestore(firebaseApp);
    firebase.googleProvider = new authModule.GoogleAuthProvider();
    firebase.createUserWithEmailAndPassword = authModule.createUserWithEmailAndPassword;
    firebase.signInWithEmailAndPassword = authModule.signInWithEmailAndPassword;
    firebase.signInWithPopup = authModule.signInWithPopup;
    firebase.signOut = authModule.signOut;
    firebase.collection = firestoreModule.collection;
    firebase.getDocs = firestoreModule.getDocs;
    firebase.limit = firestoreModule.limit;
    firebase.orderBy = firestoreModule.orderBy;
    firebase.query = firestoreModule.query;
    firebase.where = firestoreModule.where;

    authModule.onAuthStateChanged(firebase.auth, async (user) => {
      state.user = user;
      state.authReady = true;
      state.firebaseError = "";
      if (user) await loadUserData();
      render();
    });
  } catch (error) {
    state.authReady = true;
    state.firebaseError = "Firebase login could not load in this browser. Refresh and try again.";
    render();
  }
}

function go(path) {
  if (window.location.pathname === path) return;
  window.history.pushState({}, "", path);
  render();
  window.scrollTo({ top: 0, behavior: "smooth" });
}

function icon(name) {
  const map = {
    print: "P",
    file: "PDF",
    cloud: "OK",
    lock: "SEC",
    fast: "FAST",
    upload: "UP",
    shop: "ST",
    order: "OR",
    wallet: "WA",
  };
  return map[name] || "D";
}

function toast(message, kind = "info") {
  const old = document.querySelector(".toast");
  if (old) old.remove();
  const el = document.createElement("div");
  el.className = `toast toast-${kind}`;
  el.textContent = message;
  document.body.appendChild(el);
  clearTimeout(state.toastTimer);
  state.toastTimer = setTimeout(() => el.remove(), 4200);
}

function nav() {
  const current = route();
  return `
    <header class="nav">
      <div class="nav-inner">
        <button class="brand nav-link-reset" data-go="/" aria-label="Dittox home">
          <span class="brand-mark">${icon("print")}</span>
          <span class="brand-title">Dittox <small>Print orders online</small></span>
        </button>
        <nav class="nav-links" aria-label="Main navigation">
          <button class="nav-link optional" data-scroll="services">Services</button>
          <button class="nav-link optional" data-go="/store">Store tools</button>
          <button class="nav-link ${current === "app" ? "active" : ""}" data-go="/app">App login</button>
          <button class="nav-link optional" data-scroll="quote">Quote</button>
          <button class="btn btn-primary" data-go="/app">${state.user ? "Open app" : "Login"}</button>
        </nav>
      </div>
    </header>
  `;
}

function footer() {
  return `<footer class="footer"><div class="section">Dittox website runs on Firebase Hosting. Custom domain ready when dittox.com is owned.</div></footer>`;
}

function homePage() {
  return `
    <div class="shell">
      ${nav()}
      <main>
        <section class="section hero">
          <div>
            <span class="eyebrow">Firebase free-plan website</span>
            <h1>A real website for Dittox print orders.</h1>
            <p class="lead">Customers can request prints, login to the web app, upload documents, find stores, and track orders from desktop or mobile browsers.</p>
            <div class="hero-actions">
              <button class="btn btn-primary" data-go="/app">${state.user ? "Open customer app" : "Customer login"}</button>
              <button class="btn btn-outline" data-scroll="quote">Request a print</button>
              <button class="btn btn-ghost" data-go="/store">For print stores</button>
            </div>
          </div>
          <div class="hero-card" aria-label="Print order preview">
            <div class="print-ticket">
              <div class="ticket-top">
                <span class="ticket-icon">${icon("file")}</span>
                <div>
                  <div class="ticket-title">Course_notes.pdf</div>
                  <div class="ticket-meta">42 pages - 2 copies - A4</div>
                </div>
                <span class="pill">Ready</span>
              </div>
              <div class="progress"><span class="done"></span><span class="done"></span><span class="done"></span><span></span></div>
              <div class="ticket-row">
                <div><strong>1.4 km</strong><br /><span class="ticket-meta">Nearest store</span></div>
                <div><strong>Rs 84</strong><br /><span class="ticket-meta">Est. total</span></div>
              </div>
            </div>
            <div class="metric">
              <div>${icon("cloud")}<br />Synced</div>
              <div>${icon("lock")}<br />Secure</div>
              <div>${icon("fast")}<br />Fast</div>
            </div>
          </div>
        </section>

        <section class="section" id="services">
          <div class="section-head">
            <span class="eyebrow">What works now</span>
            <h2>Website first, app after login.</h2>
            <p class="lead">This separate website is not the Flutter mobile build. It has its own files and its own browser app flow.</p>
          </div>
          <div class="grid-3">
            ${services.map(([title, body]) => card(title, body)).join("")}
          </div>
        </section>

        <section class="section quote-layout" id="quote">
          <div class="panel">
            <span class="eyebrow">Quick request</span>
            <h2>Send a print request without installing anything.</h2>
            <p class="lead">Use this for website visitors. Logged-in users can continue into the full web dashboard.</p>
          </div>
          <form class="quote-card form-grid" id="quote-form">
            <div class="field"><label for="q-name">Name</label><input id="q-name" required placeholder="Your name" /></div>
            <div class="field"><label for="q-contact">Contact</label><input id="q-contact" required placeholder="Phone or email" /></div>
            <div class="field"><label for="q-service">Service</label><select id="q-service"><option>Black and white documents</option><option>Color prints</option><option>Binding and booklet</option><option>Bulk print order</option></select></div>
            <div class="field"><label for="q-notes">Notes</label><textarea id="q-notes" placeholder="Pages, copies, pickup location, deadline..."></textarea></div>
            <button class="btn btn-primary" type="submit">Prepare request</button>
          </form>
        </section>
      </main>
      ${footer()}
    </div>
  `;
}

function card(title, body) {
  return `<article class="card"><span class="mini-icon">D</span><h3 class="card-title">${title}</h3><p class="card-body">${body}</p></article>`;
}

function appPage() {
  if (!state.authReady) {
    return `<div class="shell">${nav()}<div class="auth-wrap"><div class="panel"><h2>Loading Dittox app...</h2><p class="lead">Checking Firebase login.</p></div></div></div>`;
  }

  if (!state.user) {
    return `
      <div class="shell">
        ${nav()}
        <main class="auth-wrap">
          <section class="auth-card">
            <div class="auth-copy">
              <span class="eyebrow">Customer web app</span>
              <h1>Login first. Then your app opens here.</h1>
              <p class="lead">No blank screen, no mobile app shell. This is the website app for uploads, shops, orders, and wallet.</p>
            </div>
            <form class="auth-form form-grid" id="login-form">
              ${state.firebaseError ? `<p class="status">${escapeHtml(state.firebaseError)}</p>` : ""}
              <div class="field"><label for="email">Email</label><input id="email" type="email" autocomplete="email" required /></div>
              <div class="field"><label for="password">Password</label><input id="password" type="password" autocomplete="current-password" required /></div>
              <button class="btn btn-primary" type="submit">Login and open app</button>
              <button class="btn btn-outline" type="button" id="signup-btn">Create account</button>
              <div class="divider">or</div>
              <button class="btn btn-outline" type="button" id="google-login">Continue with Google</button>
            </form>
          </section>
        </main>
      </div>
    `;
  }

  const displayName = state.user.displayName || state.user.email?.split("@")[0] || "Dittox user";
  return `
    <div class="shell">
      ${nav()}
      <main class="section app-page">
        <div class="app-top split-row">
          <div>
            <span class="eyebrow">Customer app</span>
            <h1 class="page-title">Welcome, ${escapeHtml(displayName)}</h1>
            <p class="lead">Upload files, choose a store, track orders, and manage wallet from the website.</p>
          </div>
          <button class="btn btn-outline" id="logout-btn">Logout</button>
        </div>
        <div class="app-grid">
          <aside class="app-sidebar">
            <div class="app-user">
              <strong>${escapeHtml(displayName)}</strong>
              <span>${escapeHtml(state.user.email || "Signed in")}</span>
            </div>
            ${tabButton("upload", "Upload")}
            ${tabButton("shops", "Shops")}
            ${tabButton("orders", "Orders")}
            ${tabButton("wallet", "Wallet")}
          </aside>
          <section class="app-main" id="app-main">${appTabContent()}</section>
        </div>
      </main>
    </div>
  `;
}

function tabButton(key, label) {
  return `<button class="tab-btn ${state.appTab === key ? "active" : ""}" data-tab="${key}"><span>${icon(key === "shops" ? "shop" : key === "orders" ? "order" : key)}</span>${label}</button>`;
}

function appTabContent() {
  if (state.appTab === "shops") return shopsTab();
  if (state.appTab === "orders") return ordersTab();
  if (state.appTab === "wallet") return walletTab();
  return uploadTab();
}

function uploadTab() {
  const fileLabel = state.selectedFile ? escapeHtml(state.selectedFile.name) : "No file selected yet";
  return `
    <div class="section-head">
      <span class="eyebrow">Step 1</span>
      <h2>Upload and configure documents.</h2>
      <p class="lead">Pick a PDF or image, then choose print options. Storage upload can be connected next.</p>
    </div>
    <div class="upload-drop">
      <div>
        <p><strong>${fileLabel}</strong></p>
        <input id="file-input" type="file" accept=".pdf,image/*" />
      </div>
    </div>
    <div class="grid-3" style="margin-top:16px">
      ${card("Copies", "Default: 1 copy. Add page range and color pages next.")}
      ${card("Estimate", "Example estimate: Rs 84 for 42 pages, 2 copies.")}
      ${card("Next", "Choose a store and confirm pickup after upload.")}
    </div>
  `;
}

function shopsTab() {
  const shops = state.shops.length ? state.shops : fallbackShops;
  return `
    <div class="section-head">
      <span class="eyebrow">Step 2</span>
      <h2>Choose a nearby print store.</h2>
      <p class="lead">Reads Firestore shop profiles when allowed, otherwise shows safe demo stores.</p>
    </div>
    <div class="list">
      ${shops.map((shop) => `
        <div class="list-row">
          <div><strong>${escapeHtml(shop.name || shop.storeName || "Dittox Store")}</strong><br /><span class="muted">${escapeHtml(shop.address || "Nearby")}</span></div>
          <span class="status">${escapeHtml(String(shop.avgRating || shop.status || "Open"))}</span>
        </div>`).join("")}
    </div>
  `;
}

function ordersTab() {
  const orders = state.orders.length ? state.orders : fallbackOrders;
  return `
    <div class="section-head">
      <span class="eyebrow">Step 3</span>
      <h2>Track current and past orders.</h2>
      <p class="lead">Order cards can sync from Firestore for the signed-in Firebase user.</p>
    </div>
    <div class="list">
      ${orders.map((order) => `
        <div class="list-row">
          <div><strong>${escapeHtml(order.title || order.fileName || order.id || "Print order")}</strong><br /><span class="muted">${escapeHtml(order.id || order.orderId || "Recent order")}</span></div>
          <span class="status">${escapeHtml(order.status || "Pending")}</span>
        </div>`).join("")}
    </div>
  `;
}

function walletTab() {
  return `
    <div class="section-head">
      <span class="eyebrow">Account</span>
      <h2>Wallet and PayLater controls.</h2>
      <p class="lead">Keep balance, dues, coupons, and Razorpay payment handoff in one browser screen.</p>
    </div>
    <div class="grid-3">
      ${card("Wallet balance", "Rs 0 demo balance until live wallet data is connected.")}
      ${card("PayLater", "No pending dues for this web session.")}
      ${card("Coupons", "Rewards and coupons can be pulled from Firestore.")}
    </div>
  `;
}

function storePage() {
  return `
    <div class="shell">
      ${nav()}
      <main class="dark-section">
        <section class="section hero">
          <div>
            <span class="eyebrow">store.dittox portal</span>
            <h1>Separate website tools for print stores.</h1>
            <p class="lead">Store owners get a desktop-friendly queue view without mixing it into the customer homepage.</p>
            <div class="hero-actions"><button class="btn btn-primary" data-store-login>Open store portal</button><button class="btn btn-outline" data-go="/">Customer site</button></div>
          </div>
          <div class="panel">
            <h2>Store operations</h2>
            <div class="list">
              ${["Accept web orders", "Mark jobs as printing", "Set ready for pickup"].map((item) => `<div class="list-row"><strong>${item}</strong><span class="status">Web</span></div>`).join("")}
            </div>
          </div>
        </section>
      </main>
      ${footer()}
    </div>
  `;
}

function render() {
  const current = route();
  root.innerHTML = current === "app" ? appPage() : current === "store" ? storePage() : homePage();
  bindEvents();
}

function bindEvents() {
  document.querySelectorAll("[data-go]").forEach((el) => {
    el.addEventListener("click", () => go(el.dataset.go));
  });

  document.querySelectorAll("[data-scroll]").forEach((el) => {
    el.addEventListener("click", () => {
      if (route() !== "home") {
        go("/");
        requestAnimationFrame(() => scrollToId(el.dataset.scroll));
      } else {
        scrollToId(el.dataset.scroll);
      }
    });
  });

  document.querySelectorAll("[data-tab]").forEach((el) => {
    el.addEventListener("click", () => {
      state.appTab = el.dataset.tab;
      render();
    });
  });

  document.querySelector("#quote-form")?.addEventListener("submit", (event) => {
    event.preventDefault();
    const name = document.querySelector("#q-name").value.trim();
    const contact = document.querySelector("#q-contact").value.trim();
    const service = document.querySelector("#q-service").value;
    const notes = document.querySelector("#q-notes").value.trim();
    const body = encodeURIComponent(`New Dittox print request\nName: ${name}\nContact: ${contact}\nService: ${service}\nNotes: ${notes}`);
    window.location.href = `mailto:support@dittox.in?subject=Dittox print request&body=${body}`;
    toast("Print request prepared in your mail app.");
  });

  document.querySelector("#login-form")?.addEventListener("submit", async (event) => {
    event.preventDefault();
    await login(false);
  });

  document.querySelector("#signup-btn")?.addEventListener("click", async () => {
    await login(true);
  });

  document.querySelector("#google-login")?.addEventListener("click", loginWithGoogle);
  document.querySelector("#logout-btn")?.addEventListener("click", async () => {
    if (!firebase.auth || !firebase.signOut) return toast("Firebase login is still loading.", "warn");
    await firebase.signOut(firebase.auth);
    toast("Logged out.");
  });

  document.querySelector("#file-input")?.addEventListener("change", (event) => {
    state.selectedFile = event.target.files?.[0] || null;
    render();
    if (state.selectedFile) toast(`${state.selectedFile.name} selected.`);
  });

  document.querySelector("[data-store-login]")?.addEventListener("click", () => {
    toast("Store portal shell is ready. Connect store auth next.");
  });
}

function scrollToId(id) {
  document.getElementById(id)?.scrollIntoView({ behavior: "smooth", block: "start" });
}

async function login(createAccount) {
  const email = document.querySelector("#email")?.value.trim();
  const password = document.querySelector("#password")?.value.trim();
  if (!email || !password) return toast("Enter email and password.", "warn");
  if (!firebase.auth) return toast("Firebase login is still loading. Try again in a second.", "warn");
  try {
    if (createAccount) {
      await firebase.createUserWithEmailAndPassword(firebase.auth, email, password);
      toast("Account created. App opened.");
    } else {
      await firebase.signInWithEmailAndPassword(firebase.auth, email, password);
      toast("Logged in. App opened.");
    }
  } catch (error) {
    toast(error.message || "Login failed.", "error");
  }
}

async function loginWithGoogle() {
  if (!firebase.auth) return toast("Firebase login is still loading. Try again in a second.", "warn");
  try {
    await firebase.signInWithPopup(firebase.auth, firebase.googleProvider);
    toast("Google login complete. App opened.");
  } catch (error) {
    toast(error.message || "Google login failed.", "error");
  }
}

async function loadUserData() {
  if (!state.user || !firebase.db) return;
  try {
    const shopSnap = await firebase.getDocs(
      firebase.query(firebase.collection(firebase.db, "shop_profiles"), firebase.limit(8)),
    );
    state.shops = shopSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  } catch (_) {
    state.shops = [];
  }

  try {
    const ordersQuery = firebase.query(
      firebase.collection(firebase.db, "orders"),
      firebase.where("userId", "==", state.user.uid),
      firebase.orderBy("createdAt", "desc"),
      firebase.limit(10),
    );
    const orderSnap = await firebase.getDocs(ordersQuery);
    state.orders = orderSnap.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  } catch (_) {
    state.orders = [];
  }
}

function escapeHtml(value) {
  return String(value ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}

window.addEventListener("popstate", render);

render();
clearOldFlutterServiceWorker();
initFirebase();
