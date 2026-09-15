import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';

/// Result returned after a Razorpay checkout and verification flow.
class RazorpayPaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? transactionId;
  final String? errorMessage;
  final int? errorCode;
  final bool isCancelled;

  const RazorpayPaymentResult({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.transactionId,
    this.errorMessage,
    this.errorCode,
    this.isCancelled = false,
  });
}

/// Order payload returned from the backend order creation API.
class RazorpayOrderData {
  final String orderId;
  final String key;
  final String transactionId;
  final dynamic billId;
  final double amount;

  const RazorpayOrderData({
    required this.orderId,
    required this.key,
    required this.transactionId,
    this.billId,
    required this.amount,
  });

  factory RazorpayOrderData.fromJson(Map<String, dynamic> json) {
    return RazorpayOrderData(
      orderId: (json['orderId'] ?? '').toString(),
      key: (json['key'] ?? '').toString(),
      transactionId: (json['transactionId'] ?? '').toString(),
      billId: json['billId'],
      amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0.0,
    );
  }
}

class RazorpayPaymentService {
  static final RazorpayPaymentService _instance = RazorpayPaymentService._internal();
  static RazorpayPaymentService get instance => _instance;

  Razorpay? _razorpay;
  Completer<RazorpayPaymentResult>? _paymentCompleter;
  RazorpayOrderData? _currentOrder;

  RazorpayPaymentService._internal() {
    _initRazorpay();
  }

  void _initRazorpay() {
    try {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    } catch (e) {
      debugPrint("[RazorpayPaymentService] Error initializing Razorpay SDK: $e");
    }
  }

  void dispose() {
    try {
      _razorpay?.clear();
    } catch (_) {}
    _razorpay = null;
  }

  /// Step 1: Create Order on backend using Database-configured hospital keys
  Future<RazorpayOrderData?> createOrder({
    required int appointmentId,
    required String patientId,
    required double amount,
    String? providerId,
  }) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final token = currentUser?.data?.accessToken ?? '';

    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.createPaymentOrderUrl,
        data: {
          "appointmentId": appointmentId,
          "patientId": patientId,
          "amount": amount,
          if (providerId != null && providerId.isNotEmpty) "providerId": providerId,
        },
        options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
      );

      if (res.data != null && res.data is Map) {
        final dataMap = res.data['data'];
        if (dataMap != null && dataMap is Map<String, dynamic>) {
          return RazorpayOrderData.fromJson(dataMap);
        }
      }
      return null;
    } catch (e) {
      debugPrint("[RazorpayPaymentService] Error creating order: $e");
      return null;
    }
  }

  /// Step 2: Full payment execution:
  /// - Creates Razorpay order on backend
  /// - Launches native Razorpay checkout
  /// - Verifies payment signature on backend
  Future<RazorpayPaymentResult> processPayment({
    required int appointmentId,
    required String patientId,
    required double amount,
    String? providerId,
    String? hospitalName,
    String? patientName,
    String? patientPhone,
    String? patientEmail,
    bool isTeleConsultation = false,
  }) async {
    // 1. Create order
    final orderData = await createOrder(
      appointmentId: appointmentId,
      patientId: patientId,
      amount: amount,
      providerId: providerId,
    );

    if (orderData == null || orderData.orderId.isEmpty || orderData.key.isEmpty) {
      return const RazorpayPaymentResult(
        success: false,
        errorMessage: "Unable to initialize payment gateway. Please try again or contact support.",
      );
    }

    _currentOrder = orderData;
    _paymentCompleter = Completer<RazorpayPaymentResult>();

    if (_razorpay == null) {
      _initRazorpay();
    }

    // 2. Open Razorpay Checkout modal
    final cleanPhone = (patientPhone ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final formattedPhone = cleanPhone.length > 10 ? cleanPhone.substring(cleanPhone.length - 10) : cleanPhone;

    final options = {
      'key': orderData.key,
      'amount': (orderData.amount * 100).round(), // in paise
      'name': (hospitalName != null && hospitalName.isNotEmpty) ? hospitalName : 'Yira Health',
      'description': isTeleConsultation
          ? 'Online Teleconsultation Consultation Fee'
          : 'Doctor Consultation Fee',
      'order_id': orderData.orderId,
      'timeout': 300,
      'prefill': {
        if (formattedPhone.isNotEmpty) 'contact': formattedPhone,
        if (patientEmail != null && patientEmail.isNotEmpty) 'email': patientEmail,
        if (patientName != null && patientName.isNotEmpty) 'name': patientName,
      },
      'theme': {
        'color': '#00A896', // Yira signature teal
      },
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
      'external': {
        'wallets': ['paytm', 'phonepe', 'gpay'],
      },
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint("[RazorpayPaymentService] Error launching Razorpay: $e");
      return RazorpayPaymentResult(
        success: false,
        errorMessage: "Failed to open payment gateway: $e",
      );
    }

    return _paymentCompleter!.future;
  }

  /// Internal handler: Payment Success from Razorpay SDK
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final order = _currentOrder;
    if (order == null) {
      _paymentCompleter?.complete(RazorpayPaymentResult(
        success: true,
        paymentId: response.paymentId,
        orderId: response.orderId,
        signature: response.signature,
      ));
      return;
    }

    // Verify signature on backend
    final currentUser = GlobalSession.instance.userNotifier.value;
    final token = currentUser?.data?.accessToken ?? '';

    try {
      final verifyRes = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.verifyPaymentUrl,
        data: {
          "transactionId": order.transactionId,
          "razorpay_payment_id": response.paymentId,
          "razorpay_order_id": response.orderId ?? order.orderId,
          "razorpay_signature": response.signature,
        },
        options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
      );

      final isVerified = verifyRes.statusCode == 200 ||
          verifyRes.statusCode == 201 ||
          (verifyRes.data != null && verifyRes.data['status'] == true);

      if (isVerified) {
        _paymentCompleter?.complete(RazorpayPaymentResult(
          success: true,
          paymentId: response.paymentId,
          orderId: response.orderId ?? order.orderId,
          signature: response.signature,
          transactionId: order.transactionId,
        ));
      } else {
        _paymentCompleter?.complete(RazorpayPaymentResult(
          success: false,
          paymentId: response.paymentId,
          orderId: response.orderId ?? order.orderId,
          transactionId: order.transactionId,
          errorMessage: "Payment signature verification failed.",
        ));
      }
    } catch (e) {
      debugPrint("[RazorpayPaymentService] Backend verification error: $e");
      // Even if network blips during verify, backend webhook or retry can reconcile
      _paymentCompleter?.complete(RazorpayPaymentResult(
        success: true,
        paymentId: response.paymentId,
        orderId: response.orderId ?? order.orderId,
        signature: response.signature,
        transactionId: order.transactionId,
      ));
    }
  }

  /// Internal handler: Payment Error or Cancel from Razorpay SDK
  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("[RazorpayPaymentService] Payment Error: ${response.code} - ${response.message}");
    final bool isUserCancelled = response.code == Razorpay.PAYMENT_CANCELLED ||
        (response.message?.toLowerCase().contains("cancelled") ?? false);

    _paymentCompleter?.complete(RazorpayPaymentResult(
      success: false,
      errorCode: response.code,
      errorMessage: response.message ?? (isUserCancelled ? "Payment was cancelled." : "Payment failed."),
      isCancelled: isUserCancelled,
      transactionId: _currentOrder?.transactionId,
    ));
  }

  /// Internal handler: External Wallet selected
  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("[RazorpayPaymentService] External Wallet Selected: ${response.walletName}");
    // External wallet redirects externally
  }

  /// Fetch payment details for an appointment
  Future<Map<String, dynamic>?> getPaymentForAppointment(int appointmentId) async {
    final currentUser = GlobalSession.instance.userNotifier.value;
    final token = currentUser?.data?.accessToken ?? '';

    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).get(
        "${URLs.getPaymentByAppointmentUrl}/$appointmentId",
        options: Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'}),
      );

      if (res.data != null && res.data is Map && res.data['data'] != null) {
        return Map<String, dynamic>.from(res.data['data']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
