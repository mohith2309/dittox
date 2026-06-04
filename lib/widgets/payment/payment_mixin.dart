import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Mixin for adding Razorpay payment functionality to any State class
/// Reduces boilerplate in screens that need payments
///
/// Example:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with PaymentMixin {
///   @override
///   void onPaymentSuccess(PaymentSuccessResponse response) {
///     // Handle success
///   }
///
///   @override
///   void onPaymentError(PaymentFailureResponse response) {
///     // Handle error
///   }
/// }
/// ```
mixin PaymentMixin<T extends StatefulWidget> on State<T> {
  Razorpay? _razorpay;
  bool _isProcessingPayment = false;

  bool get isProcessingPayment => _isProcessingPayment;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    super.dispose();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    _isProcessingPayment = false;
    if (mounted) {
      onPaymentSuccess(response);
    }
  }

  void _handleError(PaymentFailureResponse response) {
    _isProcessingPayment = false;
    if (mounted) {
      onPaymentError(response);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      onExternalWallet(response);
    }
  }

  /// Override this to handle payment success
  @protected
  void onPaymentSuccess(PaymentSuccessResponse response);

  /// Override this to handle payment error
  @protected
  void onPaymentError(PaymentFailureResponse response);

  /// Override this to handle external wallet selection
  @protected
  void onExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected: ${response.walletName}');
  }

  /// Initiate payment with given options
  void initiatePayment(Map<String, dynamic> options) {
    if (_razorpay == null || !mounted) return;

    _isProcessingPayment = true;
    
    try {
      _razorpay!.open(options);
    } catch (e) {
      _isProcessingPayment = false;
      debugPrint('Payment initiation error: $e');
    }
  }

  /// Clear any pending payment
  void clearPayment() {
    _razorpay?.clear();
    _isProcessingPayment = false;
  }

  /// Show a default payment error dialog
  void showPaymentErrorDialog(String message) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show a default payment success message
  void showPaymentSuccessSnackBar([String? message]) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Payment successful!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
