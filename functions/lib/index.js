"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sweepStaleQueues = exports.processLowInventory = exports.processReportExport = exports.aggregateAnalyticsEvent = exports.processOperationalOrder = exports.processPaymentRetry = exports.processPrinterQueue = exports.processWebhookOutbox = exports.processNotificationIntent = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const messaging_1 = require("firebase-admin/messaging");
const firebase_functions_1 = require("firebase-functions");
const firestore_2 = require("firebase-functions/v2/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
(0, app_1.initializeApp)();
const db = (0, firestore_1.getFirestore)();
const collections = {
    notificationIntents: "notification_intents",
    pushTokens: "push_tokens",
    notificationDeliveries: "notification_deliveries",
    webhookOutbox: "webhook_outbox",
    printerQueue: "printer_queue",
    printerRoutes: "printer_routes",
    printDispatches: "print_dispatches",
    printRetryQueue: "print_retry_queue",
    paymentRetryQueue: "payment_retry_queue",
    paymentConfirmations: "payment_confirmations",
    operationalOrders: "operational_orders",
    fraudFlags: "fraud_flags",
    analyticsEvents: "analytics_events",
    analyticsReports: "analytics_reports",
    reportExports: "report_exports",
    auditLogs: "audit_logs",
    securityAlerts: "security_alerts",
    inventoryItems: "inventory_items",
    supplierReorders: "supplier_reorders",
};
function stringValue(value, fallback = "") {
    return typeof value === "string" && value.trim().length > 0
        ? value.trim()
        : fallback;
}
function numberValue(value, fallback = 0) {
    return typeof value === "number" && Number.isFinite(value) ? value : fallback;
}
function safeId(raw) {
    const safe = raw
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9_-]+/g, "_")
        .replace(/_+/g, "_");
    return (safe || Date.now().toString()).slice(0, 180);
}
function dayKey(date = new Date()) {
    return date.toISOString().slice(0, 10);
}
async function writeAudit(action, payload) {
    const id = safeId(`${action}-${Date.now()}-${Math.random()}`);
    await db.collection(collections.auditLogs).doc(id).set({
        auditId: id,
        action,
        payload,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
}
async function markProcessed(ref, status, extra = {}) {
    await ref.set({
        ...extra,
        status,
        processedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
}
// Security Note: Validating URLs using native URL parsing helps protect against Server-Side Request Forgery (SSRF) bypasses (e.g., hex/octal encoded IPs).
function validateWebhookUrl(urlStr) {
    try {
        const url = new URL(urlStr);
        if (url.protocol !== "https:" && url.protocol !== "http:")
            return false;
        const hostname = url.hostname;
        // Block localhost and IPv6 loopback
        if (hostname === "localhost" || hostname === "127.0.0.1" || hostname === "[::1]")
            return false;
        // Block private IPs (IPv4)
        // Use regex to strictly match IP patterns, ensuring we don't false-positive on valid domains like 10.example.com
        const isIPv4 = /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.test(hostname);
        if (isIPv4) {
            if (/^(?:10|127|169\.254|192\.168)\./.test(hostname))
                return false;
            if (/^172\.(?:1[6-9]|2[0-9]|3[0-1])\./.test(hostname))
                return false;
        }
        return true;
    }
    catch {
        return false;
    }
}
async function sendWebhook(url, payload) {
    return fetch(url, {
        method: "POST",
        headers: {
            "content-type": "application/json",
            "user-agent": "dittox-firebase-functions",
        },
        body: JSON.stringify(payload),
        // Security Note: Prevent open redirects from bypassing initial validation
        redirect: "error",
    });
}
exports.processNotificationIntent = (0, firestore_2.onDocumentCreated)(`${collections.notificationIntents}/{intentId}`, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    if (stringValue(data.status, "pending") !== "pending")
        return;
    const channel = stringValue(data.channel, "push").toLowerCase();
    const userId = stringValue(data.userId || data.shopId || data.storeId);
    const title = stringValue(data.title, "Dittox");
    const body = stringValue(data.body);
    if (channel === "push") {
        if (!userId) {
            await markProcessed(snap.ref, "missing_user");
            return;
        }
        const tokensSnap = await db
            .collection(collections.pushTokens)
            .where("userId", "==", userId)
            .where("enabled", "==", true)
            .get();
        const tokens = tokensSnap.docs
            .map((doc) => stringValue(doc.data().token))
            .filter(Boolean);
        if (tokens.length === 0) {
            await markProcessed(snap.ref, "no_tokens");
            return;
        }
        const result = await (0, messaging_1.getMessaging)().sendEachForMulticast({
            tokens,
            notification: { title, body },
            data: Object.fromEntries(Object.entries((data.payload ?? {})).map(([key, value]) => [
                key,
                typeof value === "string" ? value : JSON.stringify(value),
            ])),
        });
        await db.collection(collections.notificationDeliveries).doc(snap.id).set({
            notificationId: snap.id,
            channel,
            userId,
            successCount: result.successCount,
            failureCount: result.failureCount,
            sentAt: firestore_1.FieldValue.serverTimestamp(),
        });
        await markProcessed(snap.ref, result.failureCount === tokens.length ? "failed" : "sent");
        return;
    }
    if (channel === "email" || channel === "sms") {
        const targetUrl = channel === "email" ? process.env.DITTOX_EMAIL_WEBHOOK_URL : process.env.DITTOX_SMS_WEBHOOK_URL;
        if (!targetUrl) {
            await markProcessed(snap.ref, "provider_missing", {
                providerHint: `Set ${channel === "email" ? "DITTOX_EMAIL_WEBHOOK_URL" : "DITTOX_SMS_WEBHOOK_URL"}`,
            });
            return;
        }
        // Security Note: Validate targetUrl before dispatching the webhook to prevent SSRF
        if (!validateWebhookUrl(targetUrl)) {
            await markProcessed(snap.ref, "failed", { reason: "invalid_target_url" });
            return;
        }
        const response = await sendWebhook(targetUrl, {
            channel,
            userId,
            title,
            body,
            payload: data.payload ?? {},
        });
        await markProcessed(snap.ref, response.ok ? "sent" : "failed", {
            providerStatus: response.status,
        });
        return;
    }
    await markProcessed(snap.ref, "unsupported_channel", { channel });
});
exports.processWebhookOutbox = (0, firestore_2.onDocumentCreated)(`${collections.webhookOutbox}/{webhookId}`, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    if (stringValue(data.status, "pending") !== "pending")
        return;
    const url = stringValue(data.targetUrl || data.webhookUrl || process.env.DITTOX_DEFAULT_WEBHOOK_URL);
    if (!url) {
        await markProcessed(snap.ref, "missing_target_url");
        return;
    }
    // Security Note: Validate url before dispatching the webhook to prevent SSRF
    if (!validateWebhookUrl(url)) {
        await markProcessed(snap.ref, "failed", { reason: "invalid_target_url" });
        return;
    }
    try {
        const response = await sendWebhook(url, {
            type: data.type ?? "event",
            aggregateId: data.aggregateId ?? data.orderId ?? snap.id,
            payload: data.payload ?? {},
        });
        await markProcessed(snap.ref, response.ok ? "delivered" : "failed", {
            httpStatus: response.status,
            attempts: firestore_1.FieldValue.increment(1),
        });
    }
    catch (error) {
        firebase_functions_1.logger.error("Webhook delivery failed", error);
        await markProcessed(snap.ref, "failed", {
            attempts: firestore_1.FieldValue.increment(1),
            error: String(error),
        });
    }
});
exports.processPrinterQueue = (0, firestore_2.onDocumentCreated)(`${collections.printerQueue}/{jobId}`, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const job = snap.data();
    const shopId = stringValue(job.shopId);
    const explicitPrinter = stringValue(job.printerId);
    let printerId = explicitPrinter;
    if (!printerId && shopId) {
        const routes = await db.collection(collections.printerRoutes).doc(safeId(shopId)).get();
        const routeData = routes.data();
        const routeList = Array.isArray(routeData?.routes) ? routeData.routes : [];
        const firstRoute = routeList.find((route) => typeof route?.printerId === "string");
        printerId = stringValue(firstRoute?.printerId);
    }
    const dispatchId = snap.id;
    await db.collection(collections.printDispatches).doc(dispatchId).set({
        dispatchId,
        jobId: snap.id,
        shopId,
        orderId: job.orderId ?? "",
        printerId,
        priority: job.priority ?? "normal",
        status: printerId ? "ready_for_store_device" : "needs_printer_selection",
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    await snap.ref.set({
        printerId,
        status: printerId ? "dispatch_ready" : "waiting_for_printer",
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
});
exports.processPaymentRetry = (0, firestore_2.onDocumentCreated)(`${collections.paymentRetryQueue}/{retryId}`, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    const orderId = stringValue(data.orderId);
    const paymentId = stringValue(data.paymentId, snap.id);
    const amount = numberValue(data.amount);
    await db.collection(collections.paymentConfirmations).doc(safeId(paymentId)).set({
        paymentId,
        orderId,
        amount,
        status: "retry_required",
        retryReason: data.reason ?? "",
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
    await markProcessed(snap.ref, "queued_for_manual_retry");
});
exports.processOperationalOrder = (0, firestore_2.onDocumentWritten)(`${collections.operationalOrders}/{orderId}`, async (event) => {
    const after = event.data?.after;
    if (!after?.exists)
        return;
    const order = after.data();
    if (!order)
        return;
    const orderId = stringValue(order.orderId, event.params.orderId);
    const totalCost = numberValue(order.totalCost);
    const totalPages = numberValue(order.totalPages);
    const status = stringValue(order.status, "pending").toLowerCase();
    if (totalCost <= 0 || totalPages > 2000) {
        await db.collection(collections.fraudFlags).doc(safeId(orderId)).set({
            orderId,
            reason: totalCost <= 0 ? "invalid_total_cost" : "unusually_large_page_count",
            score: totalPages > 2000 ? 80 : 50,
            status: "flagged",
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true });
    }
    if (status === "collected") {
        await writeAudit("order.collected", { orderId, status });
    }
});
exports.aggregateAnalyticsEvent = (0, firestore_2.onDocumentCreated)(`${collections.analyticsEvents}/{eventId}`, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    const name = stringValue(data.name, "custom");
    const actorId = stringValue(data.actorId || data.shopId || "global");
    const date = dayKey();
    const reportId = safeId(`${actorId}-${name}-${date}`);
    await db.collection(collections.analyticsReports).doc(reportId).set({
        reportId,
        actorId,
        type: name,
        date,
        count: firestore_1.FieldValue.increment(1),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
});
exports.processReportExport = (0, firestore_2.onDocumentCreated)(`${collections.reportExports}/{exportId}`, async (event) => {
    const snap = event.data;
    if (!snap)
        return;
    const data = snap.data();
    const reportId = stringValue(data.reportId);
    const format = stringValue(data.format, "json").toLowerCase();
    const report = reportId
        ? await db.collection(collections.analyticsReports).doc(safeId(reportId)).get()
        : null;
    await markProcessed(snap.ref, "ready", {
        format,
        generatedAt: firestore_1.FieldValue.serverTimestamp(),
        inlineData: report?.data() ?? {},
        storageMode: "inline_firestore",
    });
});
exports.processLowInventory = (0, firestore_2.onDocumentWritten)(`${collections.inventoryItems}/{itemId}`, async (event) => {
    const after = event.data?.after;
    if (!after?.exists)
        return;
    const item = after.data();
    if (!item)
        return;
    const quantity = numberValue(item.quantity);
    const reorderAt = numberValue(item.reorderAt);
    if (quantity > reorderAt)
        return;
    const shopId = stringValue(item.shopId);
    const sku = stringValue(item.sku, event.params.itemId);
    const reorderId = safeId(`${shopId}-${sku}-${dayKey()}`);
    await db.collection(collections.supplierReorders).doc(reorderId).set({
        reorderId,
        shopId,
        sku,
        suggestedQuantity: Math.max(reorderAt * 2, 1),
        status: "draft",
        reason: "low_stock",
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
});
exports.sweepStaleQueues = (0, scheduler_1.onSchedule)("every 15 minutes", async () => {
    const staleBefore = firestore_1.Timestamp.fromDate(new Date(Date.now() - 15 * 60 * 1000));
    const queueNames = [
        collections.webhookOutbox,
        collections.notificationIntents,
        collections.printerQueue,
        collections.paymentRetryQueue,
    ];
    for (const collection of queueNames) {
        const stale = await db
            .collection(collection)
            .where("status", "in", ["pending", "queued", "dispatch_ready"])
            .where("createdAt", "<", staleBefore)
            .limit(50)
            .get();
        const batch = db.batch();
        stale.docs.forEach((doc) => {
            batch.set(doc.ref, {
                status: "stale_needs_attention",
                staleAt: firestore_1.FieldValue.serverTimestamp(),
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true });
        });
        if (!stale.empty)
            await batch.commit();
    }
});
//# sourceMappingURL=index.js.map