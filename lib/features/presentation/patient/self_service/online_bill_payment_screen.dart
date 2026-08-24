import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';

class OnlineBillPaymentScreen extends StatefulWidget {
  final String? transactionId;

  const OnlineBillPaymentScreen({super.key, this.transactionId});

  @override
  State<OnlineBillPaymentScreen> createState() => _OnlineBillPaymentScreenState();
}

class _OnlineBillPaymentScreenState extends State<OnlineBillPaymentScreen> {
  bool _isProcessing = false;
  bool _paymentSuccess = false;

  void _handlePayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isProcessing = false;
      _paymentSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final isTab = isTablet(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        title: const Text('Online Bill Payment', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(screenHorizontalSpacePadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTab ? 550 : double.infinity),
            child: Container(
              padding: EdgeInsets.all(isTab ? 28 : 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
                ],
              ),
              child: _paymentSuccess
                  ? Column(
                      children: [
                        const Icon(Icons.task_alt_rounded, color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        const Text('Payment Successful!', style: TextStyle(fontFamily: appPoppinFont, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text('Transaction Ref: ${widget.transactionId ?? 'TXN-9982014'}', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Text('Your consultation receipt has been generated and sent to your registered email.', textAlign: TextAlign.center, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Downloading digital receipt PDF...')),
                            );
                          },
                          icon: const Icon(Icons.download_rounded, color: Colors.white),
                          label: const Text('Download Digital Receipt', style: TextStyle(fontFamily: appPoppinFont, color: Colors.white)),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Invoice Breakdown', style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text('UNPAID', style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber[900])),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildLineItem(context, 'Doctor Consultation Fee', '₹ 850.00'),
                        _buildLineItem(context, 'Diagnostic Lab Test (CBC)', '₹ 450.00'),
                        _buildLineItem(context, 'Hospital Service Tax (GST 5%)', '₹ 65.00'),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount Payable', style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.bold)),
                            Text('₹ 1,365.00', style: TextStyle(fontFamily: appPoppinFont, fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            onPressed: _isProcessing ? null : _handlePayment,
                            child: _isProcessing
                                ? const CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                : const Text('Pay ₹1,365 Now', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLineItem(BuildContext context, String label, String amount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[700])),
          Text(amount, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        ],
      ),
    );
  }
}
