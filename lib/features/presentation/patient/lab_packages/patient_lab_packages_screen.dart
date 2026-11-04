import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_widgets/in_app_document_viewer.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/payment/razorpay_payment_service.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';

const Color _primary = Color(0xFF2563EB);
const Color _teal = Color(0xFF00A896);

String _money(num value) {
  final f = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: value % 1 == 0 ? 0 : 2);
  return f.format(value);
}

double _num(dynamic v) => double.tryParse((v ?? 0).toString()) ?? 0.0;

/// Whole-percent saving from the original price to the offer price (both before GST); 0 when none.
int _offPercent(double original, double offer) =>
    original > 0 && offer < original ? (((original - offer) / original) * 100).round() : 0;

/// 18 rather than 18.0
String _pct(double value) => value % 1 == 0 ? value.toInt().toString() : value.toString();

String _errorText(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
  }
  return fallback;
}

Options _auth() {
  final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
  return Options(headers: {HttpHeaders.authorizationHeader: 'Bearer $token'});
}

/// Patient tab: lab packages offered in the patient's pincode, bought at a hospital of their
/// choice with Razorpay (the hospital's own account), and their lab orders with reports.
class PatientLabPackagesScreen extends StatefulWidget {
  final bool isActive;
  const PatientLabPackagesScreen({super.key, this.isActive = false});

  @override
  State<PatientLabPackagesScreen> createState() => _PatientLabPackagesScreenState();
}

class _PatientLabPackagesScreenState extends State<PatientLabPackagesScreen> {
  int _segment = 0; // 0 = packages, 1 = my orders
  final TextEditingController _pincodeController = TextEditingController();

  bool _loadingPackages = true;
  bool _packagesLoadedOnce = false;
  String? _packagesError;
  List<Map<String, dynamic>> _packages = [];

  bool _loadingOrders = false;
  String? _ordersError;
  List<Map<String, dynamic>> _orders = [];
  bool _ordersLoadedOnce = false;
  String? _openingReportFor;

  @override
  void initState() {
    super.initState();
    // The shell builds every tab at start; load only once this tab is opened
    if (widget.isActive) _loadPackages();
  }

  @override
  void didUpdateWidget(covariant PatientLabPackagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Opening (or coming back to) the tab loads or refreshes what is shown
    if (widget.isActive && !oldWidget.isActive) {
      if (!_packagesLoadedOnce || _segment == 0) {
        _loadPackages(pincode: _pincodeController.text.trim());
      } else {
        _loadOrders();
      }
    }
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadPackages({String? pincode}) async {
    setState(() {
      _loadingPackages = true;
      _packagesError = null;
    });
    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
            URLs.labPackagesUrl,
            data: {if (pincode != null && pincode.isNotEmpty) 'pincode': pincode},
            options: _auth(),
          );
      final data = (res.data is Map) ? res.data['data'] : null;
      final list = (data is Map && data['packages'] is List) ? data['packages'] as List : const [];
      final usedPincode = (data is Map ? data['pincode'] : null)?.toString() ?? '';
      if (!mounted) return;
      setState(() {
        _packagesLoadedOnce = true;
        _packages = list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        if (_pincodeController.text.trim().isEmpty && usedPincode.isNotEmpty) {
          _pincodeController.text = usedPincode;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _packagesError = _errorText(e, 'Could not load lab packages. Pull down to try again.'));
    } finally {
      if (mounted) setState(() => _loadingPackages = false);
    }
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loadingOrders = true;
      _ordersError = null;
    });
    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).get(URLs.labPackageMyOrdersUrl, options: _auth());
      final data = (res.data is Map) ? res.data['data'] : null;
      if (!mounted) return;
      setState(() {
        _orders = (data is List ? data : const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        _ordersLoadedOnce = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _ordersError = _errorText(e, 'Could not load your lab orders.'));
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  void _searchPincode() {
    final pin = _pincodeController.text.trim();
    if (pin.isNotEmpty && pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a 6-digit pincode')));
      return;
    }
    FocusScope.of(context).unfocus();
    _loadPackages(pincode: pin);
  }

  void _switchSegment(int index) {
    setState(() => _segment = index);
    if (index == 1 && !_ordersLoadedOnce) _loadOrders();
  }

  Future<void> _openPackage(Map<String, dynamic> pkg) async {
    final booked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LabPackageCheckoutSheet(package: pkg, pincode: _pincodeController.text.trim()),
    );
    if (booked != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _teal,
        content: Text(booked.isNotEmpty ? 'Payment successful. Order $booked is booked.' : 'Payment successful. Your lab package is booked.'),
      ));
      _switchSegment(1);
      _loadOrders();
    }
  }

  Future<void> _openReport(Map<String, dynamic> order) async {
    final id = order['id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _openingReportFor = id);
    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).get(
            '${URLs.labPackageOrdersUrl}/$id/report',
            options: _auth().copyWith(responseType: ResponseType.bytes),
          );
      final bytes = res.data as List<int>;
      final fileName = (order['reportFileName'] ?? '${order['orderNumber'] ?? 'lab-report'}.pdf').toString();
      final safeName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      final ext = safeName.split('.').last.toUpperCase();
      InAppDocumentViewer.show(
        context,
        title: '${order['packageName'] ?? 'Lab'} report',
        category: 'Lab Report',
        filePath: file.path,
        fileType: ext == 'PDF' ? 'PDF' : ext,
        hospitalName: order['hospitalName']?.toString(),
        date: order['reportUploadedAt']?.toString(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_errorText(e, 'Could not open the report. Try again.'))));
    } finally {
      if (mounted) setState(() => _openingReportFor = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Lab Tests',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SegmentSwitch(
                labels: const ['Packages', 'My Orders'],
                selected: _segment,
                onChanged: _switchSegment,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _segment == 0 ? _buildPackages(isDark) : _buildOrders(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildPackages(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchPincode(),
                  style: const TextStyle(fontFamily: appPoppinFont, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Your pincode',
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loadingPackages ? null : _searchPincode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Search', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadPackages(pincode: _pincodeController.text.trim()),
            child: _loadingPackages
                ? const Center(child: CircularProgressIndicator())
                : _packagesError != null
                    ? _messageList(Icons.error_outline, _packagesError!, isDark)
                    : _packages.isEmpty
                        ? _messageList(
                            Icons.science_outlined,
                            _pincodeController.text.trim().isEmpty
                                ? 'Enter your pincode to see lab packages available near you.'
                                : 'No lab packages are available for pincode ${_pincodeController.text.trim()} yet.',
                            isDark,
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                            itemCount: _packages.length,
                            separatorBuilder: (_, _) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => _PackageCard(pkg: _packages[i], isDark: isDark, onTap: () => _openPackage(_packages[i])),
                          ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrders(bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadOrders,
      child: _loadingOrders && _orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _ordersError != null
              ? _messageList(Icons.error_outline, _ordersError!, isDark)
              : _orders.isEmpty
                  ? _messageList(Icons.receipt_long_outlined, 'You have no lab orders yet. Book a package from the Packages tab.', isDark)
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      itemCount: _orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _OrderCard(
                        order: _orders[i],
                        isDark: isDark,
                        openingReport: _openingReportFor == _orders[i]['id']?.toString(),
                        onViewReport: () => _openReport(_orders[i]),
                      ),
                    ),
    );
  }

  Widget _messageList(IconData icon, String message, bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 40),
        Icon(icon, size: 48, color: isDark ? Colors.white38 : Colors.grey.shade400),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600)),
      ],
    );
  }
}

class _SegmentSwitch extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  final bool isDark;
  const _SegmentSwitch({required this.labels, required this.selected, required this.onChanged, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? (isDark ? const Color(0xFF334155) : Colors.white) : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active ? _primary : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> pkg;
  final bool isDark;
  final VoidCallback onTap;
  const _PackageCard({required this.pkg, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tests = (pkg['tests'] is List) ? (pkg['tests'] as List).map((e) => e.toString()).toList() : <String>[];
    final offer = _num(pkg['price']);
    final original = pkg['mrp'] == null ? 0.0 : _num(pkg['mrp']);
    final off = _offPercent(original, offer);
    final gstPct = _num(pkg['gstPercentage']);
    final prep = (pkg['preparation'] ?? '').toString();
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.science_rounded, color: _primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pkg['name']?.toString() ?? 'Lab package',
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(
                        '${tests.length} test${tests.length == 1 ? '' : 's'}${(pkg['reportTurnaround'] ?? '').toString().isNotEmpty ? ' · Report in ${pkg['reportTurnaround']}' : ''}',
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (tests.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                tests.take(4).join(' • ') + (tests.length > 4 ? ' +${tests.length - 4} more' : ''),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ],
            if (prep.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(children: [
                Icon(Icons.info_outline, size: 14, color: Colors.orange.shade700),
                const SizedBox(width: 4),
                Expanded(child: Text(prep, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: Colors.orange.shade800))),
              ]),
            ],
            const SizedBox(height: 12),
            // Original price struck through → offer price, the saving, and GST added on top
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (off > 0) ...[
                  Text(_money(original),
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: Colors.grey.shade500, decoration: TextDecoration.lineThrough)),
                  const SizedBox(width: 8),
                ],
                Text(_money(offer), style: const TextStyle(fontFamily: appPoppinFont, fontSize: 20, fontWeight: FontWeight.w800, color: _primary)),
                if (off > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _teal.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(8)),
                    child: Text('$off% OFF', style: const TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w800, color: _teal)),
                  ),
                ],
                const Spacer(),
                if (gstPct > 0)
                  Text('+ ${_pct(gstPct)}% GST',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isDark;
  final bool openingReport;
  final VoidCallback onViewReport;
  const _OrderCard({required this.order, required this.isDark, required this.openingReport, required this.onViewReport});

  static const Map<String, Color> _statusColors = {
    'Paid': Color(0xFF2563EB),
    'SampleCollected': Color(0xFFD97706),
    'ReportReady': Color(0xFF7C3AED),
    'Completed': Color(0xFF059669),
    'Cancelled': Color(0xFFDC2626),
  };

  @override
  Widget build(BuildContext context) {
    final status = (order['status'] ?? '').toString();
    final color = _statusColors[status] ?? Colors.grey;
    final created = DateTime.tryParse(order['createdAt']?.toString() ?? '')?.toLocal();
    final preferred = order['preferredDate']?.toString();
    final hasReport = order['hasReport'] == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(order['packageName']?.toString() ?? 'Lab package',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(order['statusLabel']?.toString() ?? status,
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w700, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(order['hospitalName']?.toString() ?? '',
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569))),
          const SizedBox(height: 2),
          Text(
            '${order['orderNumber'] ?? ''}${created != null ? ' · ${DateFormat('dd MMM yyyy').format(created)}' : ''}${preferred != null && preferred.isNotEmpty ? ' · Visit ${_formatDay(preferred)}' : ''}',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(_money(_num(order['totalAmount'])),
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(width: 6),
              Text('paid', style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600)),
              const Spacer(),
              if (hasReport)
                TextButton.icon(
                  onPressed: openingReport ? null : onViewReport,
                  icon: openingReport
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.description_outlined, size: 18),
                  label: const Text('View report', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
                )
              else if (status != 'Cancelled')
                Text('Report pending', style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDay(String ymd) {
    final d = DateTime.tryParse(ymd);
    return d == null ? ymd : DateFormat('dd MMM').format(d);
  }
}

/// Package details, the hospital to visit (its own Razorpay account takes the payment), an optional
/// preferred date and notes, the price with GST, and Pay. Pops with the order number once paid.
class _LabPackageCheckoutSheet extends StatefulWidget {
  final Map<String, dynamic> package;
  final String pincode;
  const _LabPackageCheckoutSheet({required this.package, required this.pincode});

  @override
  State<_LabPackageCheckoutSheet> createState() => _LabPackageCheckoutSheetState();
}

class _LabPackageCheckoutSheetState extends State<_LabPackageCheckoutSheet> {
  bool _loadingHospitals = true;
  String? _hospitalsError;
  List<Map<String, dynamic>> _hospitals = [];
  int? _hospitalId;
  DateTime? _preferredDate;
  final TextEditingController _notesController = TextEditingController();
  bool _paying = false;
  String? _payError;

  @override
  void initState() {
    super.initState();
    _loadHospitals();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadHospitals() async {
    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
            URLs.labPackageHospitalsUrl,
            data: {'packageId': widget.package['id'], if (widget.pincode.isNotEmpty) 'pincode': widget.pincode},
            options: _auth(),
          );
      final data = (res.data is Map) ? res.data['data'] : null;
      if (!mounted) return;
      setState(() {
        _hospitals = (data is List ? data : const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        if (_hospitals.length == 1) _hospitalId = int.tryParse(_hospitals.first['id'].toString());
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hospitalsError = _errorText(e, 'Could not load hospitals for this package.'));
    } finally {
      if (mounted) setState(() => _loadingHospitals = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Future<void> _pay() async {
    if (_hospitalId == null) {
      setState(() => _payError = 'Choose the hospital where you will give your sample.');
      return;
    }
    setState(() {
      _paying = true;
      _payError = null;
    });
    final user = GlobalSession.instance.userNotifier.value?.data;
    final result = await RazorpayPaymentService.instance.processLabPackagePayment(
      packageId: int.tryParse(widget.package['id'].toString()) ?? 0,
      hospitalId: _hospitalId!,
      pincode: widget.pincode,
      preferredDate: _preferredDate != null ? DateFormat('yyyy-MM-dd').format(_preferredDate!) : null,
      notes: _notesController.text,
      patientName: user?.firstName?.toString(),
      patientPhone: user?.phoneNumber?.toString(),
      patientEmail: user?.email?.toString(),
    );
    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(result.orderNumber ?? '');
      return;
    }
    setState(() {
      _paying = false;
      _payError = result.isCancelled ? 'Payment was cancelled. You can try again.' : (result.errorMessage ?? 'Payment failed. Please try again.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pkg = widget.package;
    final tests = (pkg['tests'] is List) ? (pkg['tests'] as List).map((e) => e.toString()).toList() : <String>[];
    final price = _num(pkg['price']);
    final original = pkg['mrp'] == null ? 0.0 : _num(pkg['mrp']);
    final off = _offPercent(original, price);
    final gstPct = _num(pkg['gstPercentage']);
    final gst = _num(pkg['gstAmount']);
    final total = _num(pkg['totalAmount']);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  Text(pkg['name']?.toString() ?? 'Lab package', style: TextStyle(fontFamily: appPoppinFont, fontSize: 20, fontWeight: FontWeight.w700, color: textColor)),
                  if ((pkg['description'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(pkg['description'].toString(), style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: subColor)),
                  ],
                  const SizedBox(height: 14),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if ((pkg['sampleType'] ?? '').toString().isNotEmpty) _chip(Icons.water_drop_outlined, pkg['sampleType'].toString(), isDark),
                    if ((pkg['reportTurnaround'] ?? '').toString().isNotEmpty) _chip(Icons.schedule, 'Report in ${pkg['reportTurnaround']}', isDark),
                    if ((pkg['preparation'] ?? '').toString().isNotEmpty) _chip(Icons.info_outline, pkg['preparation'].toString(), isDark),
                  ]),
                  const SizedBox(height: 18),
                  Text('Tests included (${tests.length})', style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 8),
                  ...tests.map((t) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          const Icon(Icons.check_circle, size: 16, color: _teal),
                          const SizedBox(width: 8),
                          Expanded(child: Text(t, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: textColor))),
                        ]),
                      )),
                  const SizedBox(height: 18),
                  Text('Choose hospital', style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 8),
                  if (_loadingHospitals)
                    const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
                  else if (_hospitalsError != null)
                    Text(_hospitalsError!, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.red))
                  else if (_hospitals.isEmpty)
                    Text('This package cannot be booked online right now.', style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: subColor))
                  else
                    ..._hospitals.map((h) {
                      final id = int.tryParse(h['id'].toString());
                      final selected = id != null && id == _hospitalId;
                      final address = [h['address'], h['city'], h['pincode']].where((v) => v != null && v.toString().trim().isNotEmpty).join(', ');
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _paying ? null : () => setState(() => _hospitalId = id),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: selected ? _primary : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)), width: selected ? 1.6 : 1),
                              color: selected ? _primary.withValues(alpha: 0.06) : Colors.transparent,
                            ),
                            child: Row(children: [
                              Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? _primary : subColor, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(h['name']?.toString() ?? '', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
                                  if (address.isNotEmpty) Text(address, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: subColor)),
                                ]),
                              ),
                              if (h['isInPincode'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: _teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                                  child: const Text('Near you', style: TextStyle(fontFamily: appPoppinFont, fontSize: 10, fontWeight: FontWeight.w700, color: _teal)),
                                ),
                            ]),
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _paying ? null : _pickDate,
                    icon: const Icon(Icons.event_outlined, size: 18),
                    label: Text(
                      _preferredDate == null ? 'Preferred visit date (optional)' : 'Visit on ${DateFormat('EEE, dd MMM yyyy').format(_preferredDate!)}',
                      style: const TextStyle(fontFamily: appPoppinFont),
                    ),
                    style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _notesController,
                    enabled: !_paying,
                    maxLength: 500,
                    maxLines: 2,
                    style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Notes for the lab (optional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      if (off > 0) ...[
                        Row(children: [
                          Text('Original price', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: subColor)),
                          const Spacer(),
                          Text(_money(original),
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: subColor, decoration: TextDecoration.lineThrough)),
                        ]),
                        const SizedBox(height: 6),
                      ],
                      _priceRow(off > 0 ? 'Offer price ($off% off)' : 'Package price', _money(price), subColor, textColor),
                      const SizedBox(height: 6),
                      _priceRow('GST (${_pct(gstPct)}%)', _money(gst), subColor, textColor),
                      const Divider(height: 18),
                      _priceRow('Total', _money(total), textColor, textColor, bold: true),
                      if (off > 0) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text('You save ${_money(original - price)}',
                              style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w700, color: _teal)),
                        ),
                      ],
                    ]),
                  ),
                  if (_payError != null) ...[
                    const SizedBox(height: 10),
                    Text(_payError!, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.red)),
                  ],
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_paying || _loadingHospitals || _hospitals.isEmpty) ? null : _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _paying
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text('Pay ${_money(total)}', style: const TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: isDark ? Colors.white70 : const Color(0xFF475569)),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF475569)))),
      ]),
    );
  }

  Widget _priceRow(String label, String value, Color labelColor, Color valueColor, {bool bold = false}) {
    return Row(children: [
      Text(label, style: TextStyle(fontFamily: appPoppinFont, fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: labelColor)),
      const Spacer(),
      Text(value, style: TextStyle(fontFamily: appPoppinFont, fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: valueColor)),
    ]);
  }
}
