import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloud_sync_guard.dart';

class BackendFeatureDescriptor {
  final int number;
  final String group;
  final String name;
  final String collection;

  const BackendFeatureDescriptor({
    required this.number,
    required this.group,
    required this.name,
    required this.collection,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'group': group,
        'name': name,
        'collection': collection,
      };
}

class BackendFeatureRegistry {
  static const List<BackendFeatureDescriptor> all = [
    BackendFeatureDescriptor(
      number: 1,
      group: 'Order Processing',
      name: 'Order received webhook',
      collection: BackendCollections.webhookOutbox,
    ),
    BackendFeatureDescriptor(
      number: 2,
      group: 'Order Processing',
      name: 'Auto-assign to printer queue',
      collection: BackendCollections.printerQueue,
    ),
    BackendFeatureDescriptor(
      number: 3,
      group: 'Order Processing',
      name: 'Status change triggers email',
      collection: BackendCollections.notificationIntents,
    ),
    BackendFeatureDescriptor(
      number: 4,
      group: 'Order Processing',
      name: 'Status change triggers SMS',
      collection: BackendCollections.notificationIntents,
    ),
    BackendFeatureDescriptor(
      number: 5,
      group: 'Order Processing',
      name: 'Payment confirmation sync',
      collection: BackendCollections.paymentConfirmations,
    ),
    BackendFeatureDescriptor(
      number: 6,
      group: 'Order Processing',
      name: 'Duplicate order detection',
      collection: BackendCollections.operationalEvents,
    ),
    BackendFeatureDescriptor(
      number: 7,
      group: 'Order Processing',
      name: 'Failed payment retry logic',
      collection: BackendCollections.paymentRetryQueue,
    ),
    BackendFeatureDescriptor(
      number: 8,
      group: 'Order Processing',
      name: 'Order aging timeout alerts',
      collection: BackendCollections.notificationIntents,
    ),
    BackendFeatureDescriptor(
      number: 9,
      group: 'Order Processing',
      name: 'Auto-reject expired orders',
      collection: BackendCollections.operationalOrders,
    ),
    BackendFeatureDescriptor(
      number: 10,
      group: 'Order Processing',
      name: 'Batch order status update',
      collection: BackendCollections.operationalEvents,
    ),
    BackendFeatureDescriptor(
      number: 11,
      group: 'Store Management',
      name: 'Shop profile CRUD API',
      collection: BackendCollections.shopProfiles,
    ),
    BackendFeatureDescriptor(
      number: 12,
      group: 'Store Management',
      name: 'Opening hours config',
      collection: BackendCollections.shopProfiles,
    ),
    BackendFeatureDescriptor(
      number: 13,
      group: 'Store Management',
      name: 'Holiday calendar override',
      collection: BackendCollections.holidayOverrides,
    ),
    BackendFeatureDescriptor(
      number: 14,
      group: 'Store Management',
      name: 'Service menu admin',
      collection: BackendCollections.serviceMenus,
    ),
    BackendFeatureDescriptor(
      number: 15,
      group: 'Store Management',
      name: 'Price list editor',
      collection: BackendCollections.priceLists,
    ),
    BackendFeatureDescriptor(
      number: 16,
      group: 'Store Management',
      name: 'Staff accounts management',
      collection: BackendCollections.staffAccounts,
    ),
    BackendFeatureDescriptor(
      number: 17,
      group: 'Store Management',
      name: 'Shift scheduling',
      collection: BackendCollections.shifts,
    ),
    BackendFeatureDescriptor(
      number: 18,
      group: 'Store Management',
      name: 'Break slot blocking',
      collection: BackendCollections.breakSlots,
    ),
    BackendFeatureDescriptor(
      number: 19,
      group: 'Store Management',
      name: 'Auto-accept rules',
      collection: BackendCollections.autoAcceptRules,
    ),
    BackendFeatureDescriptor(
      number: 20,
      group: 'Store Management',
      name: 'Rejection reason templates',
      collection: BackendCollections.rejectionTemplates,
    ),
    BackendFeatureDescriptor(
      number: 21,
      group: 'Printer Integration',
      name: 'Printer queue API',
      collection: BackendCollections.printerQueue,
    ),
    BackendFeatureDescriptor(
      number: 22,
      group: 'Printer Integration',
      name: 'Print job dispatch',
      collection: BackendCollections.printDispatches,
    ),
    BackendFeatureDescriptor(
      number: 23,
      group: 'Printer Integration',
      name: 'Printer status polling',
      collection: BackendCollections.printerStatus,
    ),
    BackendFeatureDescriptor(
      number: 24,
      group: 'Printer Integration',
      name: 'Ink level monitoring',
      collection: BackendCollections.printerStatus,
    ),
    BackendFeatureDescriptor(
      number: 25,
      group: 'Printer Integration',
      name: 'Paper tray detection',
      collection: BackendCollections.printerStatus,
    ),
    BackendFeatureDescriptor(
      number: 26,
      group: 'Printer Integration',
      name: 'Print completion webhook',
      collection: BackendCollections.webhookOutbox,
    ),
    BackendFeatureDescriptor(
      number: 27,
      group: 'Printer Integration',
      name: 'Failed print retry',
      collection: BackendCollections.printRetryQueue,
    ),
    BackendFeatureDescriptor(
      number: 28,
      group: 'Printer Integration',
      name: 'Printer health alerts',
      collection: BackendCollections.notificationIntents,
    ),
    BackendFeatureDescriptor(
      number: 29,
      group: 'Printer Integration',
      name: 'Multi-printer routing',
      collection: BackendCollections.printerRoutes,
    ),
    BackendFeatureDescriptor(
      number: 30,
      group: 'Printer Integration',
      name: 'Print job priority queue',
      collection: BackendCollections.printerQueue,
    ),
    BackendFeatureDescriptor(
      number: 31,
      group: 'Inventory & Supplies',
      name: 'Paper stock tracker',
      collection: BackendCollections.inventoryItems,
    ),
    BackendFeatureDescriptor(
      number: 32,
      group: 'Inventory & Supplies',
      name: 'Ink/toner levels',
      collection: BackendCollections.inventoryItems,
    ),
    BackendFeatureDescriptor(
      number: 33,
      group: 'Inventory & Supplies',
      name: 'Low stock alerts',
      collection: BackendCollections.notificationIntents,
    ),
    BackendFeatureDescriptor(
      number: 34,
      group: 'Inventory & Supplies',
      name: 'Supplier reorder auto',
      collection: BackendCollections.supplierReorders,
    ),
    BackendFeatureDescriptor(
      number: 35,
      group: 'Inventory & Supplies',
      name: 'Cost per page calculation',
      collection: BackendCollections.inventoryReports,
    ),
    BackendFeatureDescriptor(
      number: 36,
      group: 'Inventory & Supplies',
      name: 'Supply expense log',
      collection: BackendCollections.supplyExpenses,
    ),
    BackendFeatureDescriptor(
      number: 37,
      group: 'Inventory & Supplies',
      name: 'Inventory reports',
      collection: BackendCollections.inventoryReports,
    ),
    BackendFeatureDescriptor(
      number: 38,
      group: 'Inventory & Supplies',
      name: 'Stock adjustment audit',
      collection: BackendCollections.auditLogs,
    ),
    BackendFeatureDescriptor(
      number: 39,
      group: 'Inventory & Supplies',
      name: 'Usage trends analytics',
      collection: BackendCollections.analyticsEvents,
    ),
    BackendFeatureDescriptor(
      number: 40,
      group: 'Inventory & Supplies',
      name: 'Predictive reorder alerts',
      collection: BackendCollections.supplierReorders,
    ),
    BackendFeatureDescriptor(
      number: 41,
      group: 'Financial',
      name: 'Revenue daily report',
      collection: BackendCollections.financialReports,
    ),
    BackendFeatureDescriptor(
      number: 42,
      group: 'Financial',
      name: 'Payout calculation',
      collection: BackendCollections.payouts,
    ),
    BackendFeatureDescriptor(
      number: 43,
      group: 'Financial',
      name: 'Commission deduction',
      collection: BackendCollections.payouts,
    ),
    BackendFeatureDescriptor(
      number: 44,
      group: 'Financial',
      name: 'Tax report generation',
      collection: BackendCollections.taxReports,
    ),
    BackendFeatureDescriptor(
      number: 45,
      group: 'Financial',
      name: 'Payment settlement',
      collection: BackendCollections.settlements,
    ),
    BackendFeatureDescriptor(
      number: 46,
      group: 'Financial',
      name: 'Refund processing',
      collection: BackendCollections.refunds,
    ),
    BackendFeatureDescriptor(
      number: 47,
      group: 'Financial',
      name: 'Invoice auto-generate',
      collection: BackendCollections.invoices,
    ),
    BackendFeatureDescriptor(
      number: 48,
      group: 'Financial',
      name: 'GST filing support',
      collection: BackendCollections.gstReports,
    ),
    BackendFeatureDescriptor(
      number: 49,
      group: 'Financial',
      name: 'UPI settlement sync',
      collection: BackendCollections.upiSettlements,
    ),
    BackendFeatureDescriptor(
      number: 50,
      group: 'Financial',
      name: 'Wallet transaction log',
      collection: BackendCollections.walletTransactions,
    ),
    BackendFeatureDescriptor(
      number: 51,
      group: 'Customer Insights',
      name: 'New vs returning count',
      collection: BackendCollections.customerInsights,
    ),
    BackendFeatureDescriptor(
      number: 52,
      group: 'Customer Insights',
      name: 'Repeat customer recognition',
      collection: BackendCollections.customerProfiles,
    ),
    BackendFeatureDescriptor(
      number: 53,
      group: 'Customer Insights',
      name: 'Average order value',
      collection: BackendCollections.customerInsights,
    ),
    BackendFeatureDescriptor(
      number: 54,
      group: 'Customer Insights',
      name: 'Orders per customer',
      collection: BackendCollections.customerInsights,
    ),
    BackendFeatureDescriptor(
      number: 55,
      group: 'Customer Insights',
      name: 'Peak hours analytics',
      collection: BackendCollections.analyticsEvents,
    ),
    BackendFeatureDescriptor(
      number: 56,
      group: 'Customer Insights',
      name: 'Popular services',
      collection: BackendCollections.analyticsEvents,
    ),
    BackendFeatureDescriptor(
      number: 57,
      group: 'Customer Insights',
      name: 'Service trends',
      collection: BackendCollections.analyticsEvents,
    ),
    BackendFeatureDescriptor(
      number: 58,
      group: 'Customer Insights',
      name: 'Customer lifetime value',
      collection: BackendCollections.customerInsights,
    ),
    BackendFeatureDescriptor(
      number: 59,
      group: 'Customer Insights',
      name: 'Churn risk scoring',
      collection: BackendCollections.customerInsights,
    ),
    BackendFeatureDescriptor(
      number: 60,
      group: 'Customer Insights',
      name: 'Re-engagement campaigns',
      collection: BackendCollections.campaigns,
    ),
    BackendFeatureDescriptor(
      number: 61,
      group: 'Notifications System',
      name: 'Push token management',
      collection: BackendCollections.pushTokens,
    ),
    BackendFeatureDescriptor(
      number: 62,
      group: 'Notifications System',
      name: 'Topic subscriptions',
      collection: BackendCollections.topicSubscriptions,
    ),
    BackendFeatureDescriptor(
      number: 63,
      group: 'Notifications System',
      name: 'Scheduled notifs',
      collection: BackendCollections.scheduledNotifications,
    ),
    BackendFeatureDescriptor(
      number: 64,
      group: 'Notifications System',
      name: 'Bulk notification send',
      collection: BackendCollections.notificationIntents,
    ),
    BackendFeatureDescriptor(
      number: 65,
      group: 'Notifications System',
      name: 'Click tracking',
      collection: BackendCollections.notificationClicks,
    ),
    BackendFeatureDescriptor(
      number: 66,
      group: 'Notifications System',
      name: 'Delivery status',
      collection: BackendCollections.notificationDeliveries,
    ),
    BackendFeatureDescriptor(
      number: 67,
      group: 'Notifications System',
      name: 'Opt-out handling',
      collection: BackendCollections.notificationOptOuts,
    ),
    BackendFeatureDescriptor(
      number: 68,
      group: 'Notifications System',
      name: 'Template manager',
      collection: BackendCollections.notificationTemplates,
    ),
    BackendFeatureDescriptor(
      number: 69,
      group: 'Notifications System',
      name: 'Localization notifs',
      collection: BackendCollections.notificationTemplates,
    ),
    BackendFeatureDescriptor(
      number: 70,
      group: 'Notifications System',
      name: 'Quiet hours enforcement',
      collection: BackendCollections.quietHours,
    ),
    BackendFeatureDescriptor(
      number: 71,
      group: 'Data & Integration',
      name: 'RESTful order API',
      collection: BackendCollections.apiDefinitions,
    ),
    BackendFeatureDescriptor(
      number: 72,
      group: 'Data & Integration',
      name: 'Webhook event system',
      collection: BackendCollections.webhookOutbox,
    ),
    BackendFeatureDescriptor(
      number: 73,
      group: 'Data & Integration',
      name: 'GraphQL schema',
      collection: BackendCollections.apiDefinitions,
    ),
    BackendFeatureDescriptor(
      number: 74,
      group: 'Data & Integration',
      name: 'Firebase sync',
      collection: BackendCollections.syncState,
    ),
    BackendFeatureDescriptor(
      number: 75,
      group: 'Data & Integration',
      name: 'Cloud firestore backup',
      collection: BackendCollections.backupManifests,
    ),
    BackendFeatureDescriptor(
      number: 76,
      group: 'Data & Integration',
      name: 'AWS S3 file storage',
      collection: BackendCollections.fileStorageRefs,
    ),
    BackendFeatureDescriptor(
      number: 77,
      group: 'Data & Integration',
      name: 'CDN distribution',
      collection: BackendCollections.cdnAssets,
    ),
    BackendFeatureDescriptor(
      number: 78,
      group: 'Data & Integration',
      name: 'Rate limiting',
      collection: BackendCollections.rateLimits,
    ),
    BackendFeatureDescriptor(
      number: 79,
      group: 'Data & Integration',
      name: 'API versioning',
      collection: BackendCollections.apiVersions,
    ),
    BackendFeatureDescriptor(
      number: 80,
      group: 'Data & Integration',
      name: 'Version deprecation',
      collection: BackendCollections.apiDeprecations,
    ),
    BackendFeatureDescriptor(
      number: 81,
      group: 'Security',
      name: 'JWT token auth',
      collection: BackendCollections.authSessions,
    ),
    BackendFeatureDescriptor(
      number: 82,
      group: 'Security',
      name: 'Refresh token flow',
      collection: BackendCollections.authSessions,
    ),
    BackendFeatureDescriptor(
      number: 83,
      group: 'Security',
      name: 'OTP verification',
      collection: BackendCollections.otpChallenges,
    ),
    BackendFeatureDescriptor(
      number: 84,
      group: 'Security',
      name: 'Rate limit abuse detection',
      collection: BackendCollections.securityAlerts,
    ),
    BackendFeatureDescriptor(
      number: 85,
      group: 'Security',
      name: 'Fraud order flagging',
      collection: BackendCollections.fraudFlags,
    ),
    BackendFeatureDescriptor(
      number: 86,
      group: 'Security',
      name: 'Payment verification',
      collection: BackendCollections.paymentConfirmations,
    ),
    BackendFeatureDescriptor(
      number: 87,
      group: 'Security',
      name: 'SSL/TLS enforcement',
      collection: BackendCollections.securityPolicies,
    ),
    BackendFeatureDescriptor(
      number: 88,
      group: 'Security',
      name: 'Data encryption at rest',
      collection: BackendCollections.securityPolicies,
    ),
    BackendFeatureDescriptor(
      number: 89,
      group: 'Security',
      name: 'Audit logging',
      collection: BackendCollections.auditLogs,
    ),
    BackendFeatureDescriptor(
      number: 90,
      group: 'Security',
      name: 'Admin access controls',
      collection: BackendCollections.adminAccess,
    ),
    BackendFeatureDescriptor(
      number: 91,
      group: 'Analytics & Reporting',
      name: 'Daily order volume',
      collection: BackendCollections.analyticsReports,
    ),
    BackendFeatureDescriptor(
      number: 92,
      group: 'Analytics & Reporting',
      name: 'Revenue charts',
      collection: BackendCollections.analyticsReports,
    ),
    BackendFeatureDescriptor(
      number: 93,
      group: 'Analytics & Reporting',
      name: 'Service mix breakdown',
      collection: BackendCollections.analyticsReports,
    ),
    BackendFeatureDescriptor(
      number: 94,
      group: 'Analytics & Reporting',
      name: 'Customer acquisition',
      collection: BackendCollections.analyticsReports,
    ),
    BackendFeatureDescriptor(
      number: 95,
      group: 'Analytics & Reporting',
      name: 'Retention cohorts',
      collection: BackendCollections.analyticsReports,
    ),
    BackendFeatureDescriptor(
      number: 96,
      group: 'Analytics & Reporting',
      name: 'Funnel analytics',
      collection: BackendCollections.analyticsReports,
    ),
    BackendFeatureDescriptor(
      number: 97,
      group: 'Analytics & Reporting',
      name: 'Conversion tracking',
      collection: BackendCollections.analyticsEvents,
    ),
    BackendFeatureDescriptor(
      number: 98,
      group: 'Analytics & Reporting',
      name: 'A/B test support',
      collection: BackendCollections.abTests,
    ),
    BackendFeatureDescriptor(
      number: 99,
      group: 'Analytics & Reporting',
      name: 'Custom event tracking',
      collection: BackendCollections.analyticsEvents,
    ),
    BackendFeatureDescriptor(
      number: 100,
      group: 'Analytics & Reporting',
      name: 'Exportable reports',
      collection: BackendCollections.reportExports,
    ),
  ];

  static Future<void> publishRegistry() async {
    final batchItems = {
      for (final feature in all) feature.number.toString(): feature.toJson(),
    };
    await _BackendDb.set(
      BackendCollections.apiDefinitions,
      'feature_registry_v1',
      {
        'features': batchItems,
        'count': all.length,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }
}

class BackendCollections {
  static const operationalOrders = 'operational_orders';
  static const operationalEvents = 'operational_events';
  static const webhookOutbox = 'webhook_outbox';
  static const notificationIntents = 'notification_intents';
  static const paymentConfirmations = 'payment_confirmations';
  static const paymentRetryQueue = 'payment_retry_queue';
  static const shopProfiles = 'shop_profiles';
  static const holidayOverrides = 'holiday_overrides';
  static const serviceMenus = 'service_menus';
  static const priceLists = 'price_lists';
  static const staffAccounts = 'staff_accounts';
  static const shifts = 'staff_shifts';
  static const breakSlots = 'break_slots';
  static const autoAcceptRules = 'auto_accept_rules';
  static const rejectionTemplates = 'rejection_templates';
  static const printerQueue = 'printer_queue';
  static const printDispatches = 'print_dispatches';
  static const printerStatus = 'printer_status';
  static const printRetryQueue = 'print_retry_queue';
  static const printerRoutes = 'printer_routes';
  static const inventoryItems = 'inventory_items';
  static const supplierReorders = 'supplier_reorders';
  static const inventoryReports = 'inventory_reports';
  static const supplyExpenses = 'supply_expenses';
  static const financialReports = 'financial_reports';
  static const payouts = 'payouts';
  static const taxReports = 'tax_reports';
  static const settlements = 'settlements';
  static const refunds = 'refunds';
  static const invoices = 'invoices';
  static const gstReports = 'gst_reports';
  static const upiSettlements = 'upi_settlements';
  static const walletTransactions = 'wallet_transactions';
  static const customerProfiles = 'customer_profiles';
  static const customerInsights = 'customer_insights';
  static const campaigns = 'campaigns';
  static const pushTokens = 'push_tokens';
  static const topicSubscriptions = 'topic_subscriptions';
  static const scheduledNotifications = 'scheduled_notifications';
  static const notificationClicks = 'notification_clicks';
  static const notificationDeliveries = 'notification_deliveries';
  static const notificationOptOuts = 'notification_opt_outs';
  static const notificationTemplates = 'notification_templates';
  static const quietHours = 'quiet_hours';
  static const apiDefinitions = 'api_definitions';
  static const syncState = 'sync_state';
  static const backupManifests = 'backup_manifests';
  static const fileStorageRefs = 'file_storage_refs';
  static const cdnAssets = 'cdn_assets';
  static const rateLimits = 'rate_limits';
  static const apiVersions = 'api_versions';
  static const apiDeprecations = 'api_deprecations';
  static const authSessions = 'auth_sessions';
  static const otpChallenges = 'otp_challenges';
  static const securityAlerts = 'security_alerts';
  static const fraudFlags = 'fraud_flags';
  static const securityPolicies = 'security_policies';
  static const auditLogs = 'audit_logs';
  static const adminAccess = 'admin_access';
  static const analyticsEvents = 'analytics_events';
  static const analyticsReports = 'analytics_reports';
  static const abTests = 'ab_tests';
  static const reportExports = 'report_exports';
}

class StoreManagementService {
  static Future<void> upsertShopProfile({
    required String shopId,
    required Map<String, dynamic> profile,
  }) {
    return _BackendDb.set(BackendCollections.shopProfiles, shopId, {
      ...profile,
      'shopId': shopId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getShopProfile(String shopId) {
    return _BackendDb.get(BackendCollections.shopProfiles, shopId);
  }

  static Future<void> archiveShopProfile(String shopId) {
    return _BackendDb.set(BackendCollections.shopProfiles, shopId, {
      'archived': true,
      'archivedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setOpeningHours({
    required String shopId,
    required Map<String, dynamic> weeklyHours,
  }) {
    return _BackendDb.set(BackendCollections.shopProfiles, shopId, {
      'openingHours': weeklyHours,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setHolidayOverride({
    required String shopId,
    required DateTime date,
    required bool closed,
    String note = '',
  }) {
    final day = _BackendDb.dayKey(date);
    return _BackendDb.set(BackendCollections.holidayOverrides, '$shopId-$day', {
      'shopId': shopId,
      'date': day,
      'closed': closed,
      'note': note,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> upsertServiceMenu({
    required String shopId,
    required List<Map<String, dynamic>> services,
  }) {
    return _BackendDb.set(BackendCollections.serviceMenus, shopId, {
      'shopId': shopId,
      'services': services,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> upsertPriceList({
    required String shopId,
    required Map<String, num> prices,
  }) {
    return _BackendDb.set(BackendCollections.priceLists, shopId, {
      'shopId': shopId,
      'prices': prices,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> upsertStaffAccount({
    required String shopId,
    required String staffId,
    required Map<String, dynamic> staff,
  }) {
    return _BackendDb.set(
      BackendCollections.staffAccounts,
      '$shopId-$staffId',
      {
        ...staff,
        'shopId': shopId,
        'staffId': staffId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  static Future<void> scheduleShift({
    required String shopId,
    required String staffId,
    required DateTime startsAt,
    required DateTime endsAt,
    String role = 'staff',
  }) {
    final id = _BackendDb.id('$shopId-$staffId-${startsAt.toIso8601String()}');
    return _BackendDb.set(BackendCollections.shifts, id, {
      'shiftId': id,
      'shopId': shopId,
      'staffId': staffId,
      'role': role,
      'startsAt': Timestamp.fromDate(startsAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> blockBreakSlot({
    required String shopId,
    required DateTime startsAt,
    required DateTime endsAt,
    String reason = 'break',
  }) {
    final id = _BackendDb.id('$shopId-${startsAt.toIso8601String()}');
    return _BackendDb.set(BackendCollections.breakSlots, id, {
      'slotId': id,
      'shopId': shopId,
      'reason': reason,
      'startsAt': Timestamp.fromDate(startsAt),
      'endsAt': Timestamp.fromDate(endsAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setAutoAcceptRules({
    required String shopId,
    required Map<String, dynamic> rules,
  }) {
    return _BackendDb.set(BackendCollections.autoAcceptRules, shopId, {
      'shopId': shopId,
      'rules': rules,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveRejectionTemplates({
    required String shopId,
    required List<String> templates,
  }) {
    return _BackendDb.set(BackendCollections.rejectionTemplates, shopId, {
      'shopId': shopId,
      'templates': templates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class PrinterIntegrationService {
  static Future<void> enqueuePrintJob({
    required String shopId,
    required String orderId,
    required List<String> fileRefs,
    String priority = 'normal',
    String? printerId,
  }) {
    final id = _BackendDb.id('$shopId-$orderId-${DateTime.now()}');
    return _BackendDb.set(BackendCollections.printerQueue, id, {
      'jobId': id,
      'shopId': shopId,
      'orderId': orderId,
      'fileRefs': fileRefs,
      'printerId': printerId ?? '',
      'priority': priority,
      'status': 'queued',
      'attempts': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> dispatchPrintJob({
    required String jobId,
    required String printerId,
  }) {
    return _BackendDb.set(BackendCollections.printDispatches, jobId, {
      'jobId': jobId,
      'printerId': printerId,
      'status': 'dispatching',
      'dispatchedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> recordPrinterStatus({
    required String printerId,
    required String shopId,
    required String status,
    int? inkPercent,
    int? tonerPercent,
    int? paperPercent,
    String trayStatus = '',
  }) async {
    await _BackendDb.set(BackendCollections.printerStatus, printerId, {
      'printerId': printerId,
      'shopId': shopId,
      'status': status,
      'inkPercent': inkPercent,
      'tonerPercent': tonerPercent,
      'paperPercent': paperPercent,
      'trayStatus': trayStatus,
      'polledAt': FieldValue.serverTimestamp(),
    });

    final lowInk = (inkPercent != null && inkPercent <= 15) ||
        (tonerPercent != null && tonerPercent <= 15);
    final lowPaper = paperPercent != null && paperPercent <= 15;
    if (lowInk || lowPaper || status.toLowerCase() == 'offline') {
      await NotificationOpsService.queueNotification(
        userId: shopId,
        channel: 'push',
        title: 'Printer needs attention',
        body: '$printerId is $status. Check ink/paper before printing.',
        payload: {'printerId': printerId, 'status': status},
      );
    }
  }

  static Future<void> completePrintJob({
    required String jobId,
    required String orderId,
    required String shopId,
  }) async {
    await _BackendDb.set(BackendCollections.printDispatches, jobId, {
      'jobId': jobId,
      'status': 'completed',
      'completedAt': FieldValue.serverTimestamp(),
    });
    await DataIntegrationService.enqueueWebhook(
      type: 'print.completed',
      aggregateId: jobId,
      payload: {'jobId': jobId, 'orderId': orderId, 'shopId': shopId},
    );
  }

  static Future<void> schedulePrintRetry({
    required String jobId,
    required String reason,
    int attempt = 1,
  }) {
    return _BackendDb.set(BackendCollections.printRetryQueue, jobId, {
      'jobId': jobId,
      'reason': reason,
      'attempt': attempt,
      'status': 'scheduled',
      'nextRetryAt': Timestamp.fromDate(
        DateTime.now().add(Duration(minutes: attempt * 2)),
      ),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setPrinterRoutes({
    required String shopId,
    required List<Map<String, dynamic>> routes,
  }) {
    return _BackendDb.set(BackendCollections.printerRoutes, shopId, {
      'shopId': shopId,
      'routes': routes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class InventorySuppliesService {
  static Future<void> upsertStockItem({
    required String shopId,
    required String sku,
    required String name,
    required num quantity,
    required num reorderAt,
    required num unitCost,
    String unit = 'pcs',
  }) async {
    final id = _BackendDb.id('$shopId-$sku');
    await _BackendDb.set(BackendCollections.inventoryItems, id, {
      'shopId': shopId,
      'sku': sku,
      'name': name,
      'quantity': quantity,
      'reorderAt': reorderAt,
      'unitCost': unitCost,
      'unit': unit,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (quantity <= reorderAt) {
      await createLowStockAlert(shopId: shopId, sku: sku, quantity: quantity);
      await createSupplierReorder(
        shopId: shopId,
        sku: sku,
        suggestedQuantity: reorderAt * 2,
      );
    }
  }

  static Future<void> createLowStockAlert({
    required String shopId,
    required String sku,
    required num quantity,
  }) {
    return NotificationOpsService.queueNotification(
      userId: shopId,
      channel: 'push',
      title: 'Low stock',
      body: '$sku is low: $quantity left.',
      payload: {'sku': sku, 'quantity': quantity},
    );
  }

  static Future<void> createSupplierReorder({
    required String shopId,
    required String sku,
    required num suggestedQuantity,
  }) {
    final id = _BackendDb.id('$shopId-$sku-${DateTime.now()}');
    return _BackendDb.set(BackendCollections.supplierReorders, id, {
      'reorderId': id,
      'shopId': shopId,
      'sku': sku,
      'suggestedQuantity': suggestedQuantity,
      'status': 'draft',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> logSupplyExpense({
    required String shopId,
    required String sku,
    required num amount,
    String note = '',
  }) {
    final id = _BackendDb.id('$shopId-$sku-${DateTime.now()}');
    return _BackendDb.set(BackendCollections.supplyExpenses, id, {
      'expenseId': id,
      'shopId': shopId,
      'sku': sku,
      'amount': amount,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> auditStockAdjustment({
    required String shopId,
    required String sku,
    required num before,
    required num after,
    required String actor,
    String reason = '',
  }) {
    return SecurityOperationsService.writeAuditLog(
      actorId: actor,
      action: 'stock.adjusted',
      targetId: '$shopId-$sku',
      payload: {
        'shopId': shopId,
        'sku': sku,
        'before': before,
        'after': after,
        'reason': reason,
      },
    );
  }

  static Future<void> writeInventoryReport({
    required String shopId,
    required DateTime date,
    required num paperUsed,
    required num inkUsed,
    required num pagesPrinted,
    required num totalSupplyCost,
  }) {
    final day = _BackendDb.dayKey(date);
    final costPerPage = pagesPrinted <= 0 ? 0 : totalSupplyCost / pagesPrinted;
    return _BackendDb.set(BackendCollections.inventoryReports, '$shopId-$day', {
      'shopId': shopId,
      'date': day,
      'paperUsed': paperUsed,
      'inkUsed': inkUsed,
      'pagesPrinted': pagesPrinted,
      'totalSupplyCost': totalSupplyCost,
      'costPerPage': costPerPage,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> recordUsageTrend({
    required String shopId,
    required String sku,
    required num quantityUsed,
  }) {
    return AnalyticsReportingService.trackCustomEvent(
      name: 'inventory.usage',
      actorId: shopId,
      payload: {'shopId': shopId, 'sku': sku, 'quantityUsed': quantityUsed},
    );
  }

  static Future<void> createPredictiveReorderAlert({
    required String shopId,
    required String sku,
    required num projectedDaysLeft,
  }) {
    return createSupplierReorder(
      shopId: shopId,
      sku: sku,
      suggestedQuantity: projectedDaysLeft < 3 ? 100 : 50,
    );
  }
}

class FinancialOpsService {
  static Future<void> writeDailyRevenueReport({
    required String shopId,
    required DateTime date,
    required num grossRevenue,
    required num refunds,
    required int orderCount,
  }) {
    final day = _BackendDb.dayKey(date);
    return _BackendDb.set(BackendCollections.financialReports, '$shopId-$day', {
      'shopId': shopId,
      'date': day,
      'grossRevenue': grossRevenue,
      'refunds': refunds,
      'netRevenue': grossRevenue - refunds,
      'orderCount': orderCount,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> calculatePayout({
    required String shopId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required num grossAmount,
    num commissionPercent = 0,
  }) {
    final commission = grossAmount * commissionPercent / 100;
    final payout = grossAmount - commission;
    final id = _BackendDb.id('$shopId-${periodStart.toIso8601String()}');
    return _BackendDb.set(BackendCollections.payouts, id, {
      'payoutId': id,
      'shopId': shopId,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'grossAmount': grossAmount,
      'commissionPercent': commissionPercent,
      'commission': commission,
      'payoutAmount': payout,
      'status': 'calculated',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> generateTaxReport({
    required String shopId,
    required DateTime periodStart,
    required DateTime periodEnd,
    required num taxableRevenue,
    num gstPercent = 18,
  }) {
    final tax = taxableRevenue * gstPercent / 100;
    final id = _BackendDb.id('$shopId-tax-${periodStart.toIso8601String()}');
    return _BackendDb.set(BackendCollections.taxReports, id, {
      'reportId': id,
      'shopId': shopId,
      'periodStart': Timestamp.fromDate(periodStart),
      'periodEnd': Timestamp.fromDate(periodEnd),
      'taxableRevenue': taxableRevenue,
      'gstPercent': gstPercent,
      'taxDue': tax,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> recordSettlement({
    required String settlementId,
    required String shopId,
    required num amount,
    String method = 'upi',
  }) {
    return _BackendDb.set(BackendCollections.settlements, settlementId, {
      'settlementId': settlementId,
      'shopId': shopId,
      'amount': amount,
      'method': method,
      'status': 'settled',
      'settledAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> processRefund({
    required String refundId,
    required String orderId,
    required num amount,
    required String reason,
  }) {
    return _BackendDb.set(BackendCollections.refunds, refundId, {
      'refundId': refundId,
      'orderId': orderId,
      'amount': amount,
      'reason': reason,
      'status': 'requested',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> generateInvoice({
    required String invoiceId,
    required String orderId,
    required String customerId,
    required num amount,
    required List<Map<String, dynamic>> lineItems,
  }) {
    return _BackendDb.set(BackendCollections.invoices, invoiceId, {
      'invoiceId': invoiceId,
      'orderId': orderId,
      'customerId': customerId,
      'amount': amount,
      'lineItems': lineItems,
      'status': 'issued',
      'issuedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createGstFilingDraft({
    required String shopId,
    required String gstin,
    required DateTime month,
    required num taxableRevenue,
  }) {
    final id = _BackendDb.id('$shopId-gst-${month.year}-${month.month}');
    return _BackendDb.set(BackendCollections.gstReports, id, {
      'reportId': id,
      'shopId': shopId,
      'gstin': gstin,
      'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
      'taxableRevenue': taxableRevenue,
      'status': 'draft',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> syncUpiSettlement({
    required String utr,
    required String shopId,
    required num amount,
  }) {
    return _BackendDb.set(BackendCollections.upiSettlements, utr, {
      'utr': utr,
      'shopId': shopId,
      'amount': amount,
      'syncedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> logWalletTransaction({
    required String userId,
    required String type,
    required num amount,
    String note = '',
  }) {
    final id = _BackendDb.id('$userId-$type-${DateTime.now()}');
    return _BackendDb.set(BackendCollections.walletTransactions, id, {
      'transactionId': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

class CustomerInsightsService {
  static Future<void> upsertCustomerOrderStats({
    required String customerId,
    required String shopId,
    required num orderAmount,
  }) async {
    final profileId = _BackendDb.id('$shopId-$customerId');
    final existing =
        await _BackendDb.get(BackendCollections.customerProfiles, profileId);
    final previousOrders = (existing?['orderCount'] as num?)?.toInt() ?? 0;
    final previousSpend = (existing?['lifetimeValue'] as num?) ?? 0;
    final nextOrders = previousOrders + 1;
    final nextSpend = previousSpend + orderAmount;

    await _BackendDb.set(BackendCollections.customerProfiles, profileId, {
      'profileId': profileId,
      'customerId': customerId,
      'shopId': shopId,
      'orderCount': nextOrders,
      'lifetimeValue': nextSpend,
      'averageOrderValue': nextSpend / nextOrders,
      'isReturning': previousOrders > 0,
      'lastOrderAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> writeInsightSnapshot({
    required String shopId,
    required DateTime date,
    required int newCustomers,
    required int returningCustomers,
    required num averageOrderValue,
    required num customerLifetimeValue,
    required num churnRiskScore,
  }) {
    final id = _BackendDb.id('$shopId-${_BackendDb.dayKey(date)}');
    return _BackendDb.set(BackendCollections.customerInsights, id, {
      'shopId': shopId,
      'date': _BackendDb.dayKey(date),
      'newCustomers': newCustomers,
      'returningCustomers': returningCustomers,
      'averageOrderValue': averageOrderValue,
      'customerLifetimeValue': customerLifetimeValue,
      'churnRiskScore': churnRiskScore,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> recordServiceTrend({
    required String shopId,
    required String service,
    required num count,
  }) {
    return AnalyticsReportingService.trackCustomEvent(
      name: 'service.trend',
      actorId: shopId,
      payload: {'shopId': shopId, 'service': service, 'count': count},
    );
  }

  static Future<void> createReEngagementCampaign({
    required String shopId,
    required String campaignId,
    required List<String> customerIds,
    required String message,
  }) {
    return _BackendDb.set(BackendCollections.campaigns, campaignId, {
      'campaignId': campaignId,
      'shopId': shopId,
      'customerIds': customerIds,
      'message': message,
      'status': 'draft',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

class NotificationOpsService {
  static Future<void> registerPushToken({
    required String userId,
    required String token,
    String platform = 'android',
  }) {
    final id = _BackendDb.id('$userId-$token');
    return _BackendDb.set(BackendCollections.pushTokens, id, {
      'userId': userId,
      'token': token,
      'platform': platform,
      'enabled': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> subscribeTopic({
    required String userId,
    required String topic,
  }) {
    final id = _BackendDb.id('$userId-$topic');
    return _BackendDb.set(BackendCollections.topicSubscriptions, id, {
      'userId': userId,
      'topic': topic,
      'subscribed': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> queueNotification({
    required String userId,
    required String channel,
    required String title,
    required String body,
    Map<String, dynamic> payload = const {},
    DateTime? scheduledAt,
  }) {
    final collection = scheduledAt == null
        ? BackendCollections.notificationIntents
        : BackendCollections.scheduledNotifications;
    final id = _BackendDb.id('$userId-$channel-$title-${DateTime.now()}');
    return _BackendDb.set(collection, id, {
      'notificationId': id,
      'userId': userId,
      'channel': channel,
      'title': title,
      'body': body,
      'payload': payload,
      'status': 'pending',
      if (scheduledAt != null) 'scheduledAt': Timestamp.fromDate(scheduledAt),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> queueBulkNotification({
    required List<String> userIds,
    required String channel,
    required String title,
    required String body,
  }) async {
    for (final userId in userIds) {
      await queueNotification(
        userId: userId,
        channel: channel,
        title: title,
        body: body,
      );
    }
  }

  static Future<void> trackClick({
    required String notificationId,
    required String userId,
  }) {
    final id = _BackendDb.id('$notificationId-$userId-${DateTime.now()}');
    return _BackendDb.set(BackendCollections.notificationClicks, id, {
      'notificationId': notificationId,
      'userId': userId,
      'clickedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> recordDeliveryStatus({
    required String notificationId,
    required String status,
    String providerMessageId = '',
  }) {
    return _BackendDb.set(
      BackendCollections.notificationDeliveries,
      notificationId,
      {
        'notificationId': notificationId,
        'status': status,
        'providerMessageId': providerMessageId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  static Future<void> setOptOut({
    required String userId,
    required String channel,
    required bool optedOut,
  }) {
    final id = _BackendDb.id('$userId-$channel');
    return _BackendDb.set(BackendCollections.notificationOptOuts, id, {
      'userId': userId,
      'channel': channel,
      'optedOut': optedOut,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveTemplate({
    required String templateId,
    required String locale,
    required String title,
    required String body,
  }) {
    return _BackendDb.set(
        BackendCollections.notificationTemplates, templateId, {
      'templateId': templateId,
      'locale': locale,
      'title': title,
      'body': body,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setQuietHours({
    required String userId,
    required String startsAt,
    required String endsAt,
    String timezone = 'Asia/Kolkata',
  }) {
    return _BackendDb.set(BackendCollections.quietHours, userId, {
      'userId': userId,
      'startsAt': startsAt,
      'endsAt': endsAt,
      'timezone': timezone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class DataIntegrationService {
  static Future<void> publishRestOrderApiDefinition() {
    return _BackendDb.set(BackendCollections.apiDefinitions, 'rest_orders_v1', {
      'type': 'rest',
      'version': 'v1',
      'resources': ['orders', 'shops', 'payments', 'printers'],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> enqueueWebhook({
    required String type,
    required String aggregateId,
    required Map<String, dynamic> payload,
  }) {
    final id = _BackendDb.id('$type-$aggregateId-${DateTime.now()}');
    return _BackendDb.set(BackendCollections.webhookOutbox, id, {
      'webhookId': id,
      'type': type,
      'aggregateId': aggregateId,
      'payload': payload,
      'status': 'pending',
      'attempts': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> publishGraphQlSchema() {
    const schema = '''
type Order { orderId: ID!, status: String!, totalCost: Float, totalPages: Int }
type Shop { shopId: ID!, name: String, openingHours: String }
type PrinterJob { jobId: ID!, orderId: ID!, status: String! }
type Query { order(id: ID!): Order, shop(id: ID!): Shop }
type Mutation { updateOrderStatus(id: ID!, status: String!): Order }
''';
    return _BackendDb.set(BackendCollections.apiDefinitions, 'graphql_v1', {
      'type': 'graphql',
      'version': 'v1',
      'schema': schema,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateSyncState({
    required String scope,
    required String status,
  }) {
    return _BackendDb.set(BackendCollections.syncState, scope, {
      'scope': scope,
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createBackupManifest({
    required String backupId,
    required List<String> collections,
  }) {
    return _BackendDb.set(BackendCollections.backupManifests, backupId, {
      'backupId': backupId,
      'collections': collections,
      'status': 'requested',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveFileStorageRef({
    required String fileId,
    required String storageUrl,
    String provider = 's3',
  }) {
    return _BackendDb.set(BackendCollections.fileStorageRefs, fileId, {
      'fileId': fileId,
      'provider': provider,
      'storageUrl': storageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> publishCdnAsset({
    required String assetId,
    required String originUrl,
    required String cdnUrl,
  }) {
    return _BackendDb.set(BackendCollections.cdnAssets, assetId, {
      'assetId': assetId,
      'originUrl': originUrl,
      'cdnUrl': cdnUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setRateLimit({
    required String key,
    required int limit,
    required Duration window,
  }) {
    return _BackendDb.set(BackendCollections.rateLimits, key, {
      'key': key,
      'limit': limit,
      'windowSeconds': window.inSeconds,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> publishApiVersion({
    required String version,
    required bool active,
  }) {
    return _BackendDb.set(BackendCollections.apiVersions, version, {
      'version': version,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deprecateApiVersion({
    required String version,
    required DateTime sunsetAt,
    required String message,
  }) {
    return _BackendDb.set(BackendCollections.apiDeprecations, version, {
      'version': version,
      'sunsetAt': Timestamp.fromDate(sunsetAt),
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

class SecurityOperationsService {
  static Future<void> saveAuthSession({
    required String userId,
    required String sessionId,
    required DateTime expiresAt,
  }) {
    return _BackendDb.set(BackendCollections.authSessions, sessionId, {
      'sessionId': sessionId,
      'userId': userId,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> rotateRefreshToken({
    required String sessionId,
    required String rotationId,
  }) {
    return _BackendDb.set(BackendCollections.authSessions, sessionId, {
      'lastRotationId': rotationId,
      'rotatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> recordOtpChallenge({
    required String challengeId,
    required String target,
    required bool verified,
  }) {
    return _BackendDb.set(BackendCollections.otpChallenges, challengeId, {
      'challengeId': challengeId,
      'target': target,
      'verified': verified,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> recordRateLimitAbuse({
    required String actorId,
    required String endpoint,
    required int count,
  }) {
    final id = _BackendDb.id('$actorId-$endpoint-${DateTime.now()}');
    return _BackendDb.set(BackendCollections.securityAlerts, id, {
      'alertId': id,
      'type': 'rate_limit_abuse',
      'actorId': actorId,
      'endpoint': endpoint,
      'count': count,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> flagFraudOrder({
    required String orderId,
    required String reason,
    num score = 0,
  }) {
    return _BackendDb.set(BackendCollections.fraudFlags, orderId, {
      'orderId': orderId,
      'reason': reason,
      'score': score,
      'status': 'flagged',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> recordPaymentVerification({
    required String paymentId,
    required bool verified,
    String reason = '',
  }) {
    return _BackendDb.set(BackendCollections.paymentConfirmations, paymentId, {
      'paymentId': paymentId,
      'verified': verified,
      'verificationReason': reason,
      'verifiedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> enforceSecurityPolicies() {
    return _BackendDb.set(BackendCollections.securityPolicies, 'default', {
      'requireTls': true,
      'encryptionAtRest': true,
      'minTokenEntropy': 128,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static bool isTlsUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.scheme == 'https';
  }

  static Future<void> writeAuditLog({
    required String actorId,
    required String action,
    required String targetId,
    Map<String, dynamic> payload = const {},
  }) {
    final id = _BackendDb.id('$actorId-$action-$targetId-${DateTime.now()}');
    return _BackendDb.set(BackendCollections.auditLogs, id, {
      'auditId': id,
      'actorId': actorId,
      'action': action,
      'targetId': targetId,
      'payload': payload,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> setAdminAccess({
    required String userId,
    required List<String> roles,
    required List<String> permissions,
  }) {
    return _BackendDb.set(BackendCollections.adminAccess, userId, {
      'userId': userId,
      'roles': roles,
      'permissions': permissions,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class AnalyticsReportingService {
  static Future<void> trackCustomEvent({
    required String name,
    required String actorId,
    Map<String, dynamic> payload = const {},
  }) {
    final id = _BackendDb.id('$name-$actorId-${DateTime.now()}');
    return _BackendDb.set(BackendCollections.analyticsEvents, id, {
      'eventId': id,
      'name': name,
      'actorId': actorId,
      'payload': payload,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> writeDailyOrderVolume({
    required String shopId,
    required DateTime date,
    required int orderCount,
  }) {
    return _writeReport(
      shopId: shopId,
      date: date,
      type: 'daily_order_volume',
      data: {'orderCount': orderCount},
    );
  }

  static Future<void> writeRevenueChartPoint({
    required String shopId,
    required DateTime date,
    required num revenue,
  }) {
    return _writeReport(
      shopId: shopId,
      date: date,
      type: 'revenue_chart',
      data: {'revenue': revenue},
    );
  }

  static Future<void> writeServiceMixBreakdown({
    required String shopId,
    required DateTime date,
    required Map<String, num> serviceMix,
  }) {
    return _writeReport(
      shopId: shopId,
      date: date,
      type: 'service_mix',
      data: {'serviceMix': serviceMix},
    );
  }

  static Future<void> writeCustomerAcquisition({
    required String shopId,
    required DateTime date,
    required int acquiredCustomers,
  }) {
    return _writeReport(
      shopId: shopId,
      date: date,
      type: 'customer_acquisition',
      data: {'acquiredCustomers': acquiredCustomers},
    );
  }

  static Future<void> writeRetentionCohort({
    required String shopId,
    required String cohortId,
    required Map<String, num> retention,
  }) {
    return _BackendDb.set(
      BackendCollections.analyticsReports,
      _BackendDb.id('$shopId-retention-$cohortId'),
      {
        'shopId': shopId,
        'type': 'retention_cohort',
        'cohortId': cohortId,
        'retention': retention,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  static Future<void> writeFunnelStep({
    required String funnel,
    required String step,
    required int count,
  }) {
    return _BackendDb.set(
      BackendCollections.analyticsReports,
      _BackendDb.id('$funnel-$step-${_BackendDb.dayKey(DateTime.now())}'),
      {
        'type': 'funnel',
        'funnel': funnel,
        'step': step,
        'count': count,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  static Future<void> trackConversion({
    required String actorId,
    required String conversion,
    num value = 0,
  }) {
    return trackCustomEvent(
      name: 'conversion.$conversion',
      actorId: actorId,
      payload: {'value': value},
    );
  }

  static Future<void> configureAbTest({
    required String testId,
    required List<String> variants,
    required Map<String, dynamic> allocation,
  }) {
    return _BackendDb.set(BackendCollections.abTests, testId, {
      'testId': testId,
      'variants': variants,
      'allocation': allocation,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> requestReportExport({
    required String reportId,
    required String format,
    required String requestedBy,
  }) {
    final id = _BackendDb.id('$reportId-$format-${DateTime.now()}');
    return _BackendDb.set(BackendCollections.reportExports, id, {
      'exportId': id,
      'reportId': reportId,
      'format': format,
      'requestedBy': requestedBy,
      'status': 'queued',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> _writeReport({
    required String shopId,
    required DateTime date,
    required String type,
    required Map<String, dynamic> data,
  }) {
    final id = _BackendDb.id('$shopId-$type-${_BackendDb.dayKey(date)}');
    return _BackendDb.set(BackendCollections.analyticsReports, id, {
      'reportId': id,
      'shopId': shopId,
      'type': type,
      'date': _BackendDb.dayKey(date),
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class _BackendDb {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> set(
    String collection,
    String docId,
    Map<String, dynamic> data,
  ) {
    return CloudSyncGuard.runOptionalWrite(() async {
      await _db.collection(collection).doc(id(docId)).set(
            data,
            SetOptions(merge: true),
          );
    });
  }

  static Future<Map<String, dynamic>?> get(
    String collection,
    String docId,
  ) async {
    if (!CloudSyncGuard.cloudSyncEnabled) return null;
    try {
      final doc = await _db.collection(collection).doc(id(docId)).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static String dayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String id(Object raw) {
    final safe = raw
        .toString()
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_\-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (safe.isEmpty) return DateTime.now().microsecondsSinceEpoch.toString();
    return safe.length > 180 ? safe.substring(0, 180) : safe;
  }
}
