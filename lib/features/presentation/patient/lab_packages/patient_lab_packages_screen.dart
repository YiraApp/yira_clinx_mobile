import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_widgets/in_app_document_viewer.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/services/payment/razorpay_payment_service.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/di/dependency_injection.dart';
import 'lab_collection_address.dart';
import '../wallet/wallet_attachment.dart';
import 'lab_package_cover.dart';

const Color _primary = Color(0xFF2563EB);

/// The screen's one accent: the app's blue.
const Color _accent = Color(0xFF2563EB);

String _money(num value) {
  final f = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: value % 1 == 0 ? 0 : 2);
  return f.format(value);
}

double _num(dynamic v) => double.tryParse((v ?? 0).toString()) ?? 0.0;

/// "Free" for a package with nothing to pay, else the amount.
String _priceLabel(num value) => value <= 0 ? 'Free' : _money(value);

/// "No fasting needed" is good news, not a warning.
bool _prepIsEasy(String prep) => RegExp(r'\b(no|not|without)\b.*\b(fast|fasting|preparation|needed|required)\b', caseSensitive: false).hasMatch(prep);

/// Whole-percent saving from the original price to the offer price (both before GST); 0 when none.
int _offPercent(double original, double offer) => original > 0 && offer < original ? (((original - offer) / original) * 100).round() : 0;

/// 18 rather than 18.0
String _pct(double value) => value % 1 == 0 ? value.toInt().toString() : value.toString();

/// "Fri, 06 Nov" for a "YYYY-MM-DD" visit date
String _slotDay(String? ymd) {
  final d = DateTime.tryParse(ymd ?? '');
  return d == null ? (ymd ?? '') : DateFormat('EEE, dd MMM').format(d);
}

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

  /// Nothing offered in the pincode: the default hospital's packages, shown below the notice
  List<Map<String, dynamic>> _fallbackPackages = [];
  String _fallbackHospitalName = '';

  /// Finding the pincode from the device's location
  bool _locating = false;
  bool _firstLoadStarted = false;

  /// "Kukatpally, Hyderabad" while the pincode shown came from the current location
  String? _locationLabel;

  bool _loadingOrders = false;
  String? _ordersError;
  List<Map<String, dynamic>> _orders = [];
  bool _ordersLoadedOnce = false;
  String? _openingReportFor;

  @override
  void initState() {
    super.initState();
    // The shell builds every tab at start; load only once this tab is opened
    if (widget.isActive) _firstLoad();
  }

  @override
  void didUpdateWidget(covariant PatientLabPackagesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Opening (or coming back to) the tab loads or refreshes what is shown
    if (widget.isActive && !oldWidget.isActive) {
      if (!_firstLoadStarted) {
        _firstLoad();
      } else if (_locating) {
        // still finding the location; the load follows it
      } else if (!_packagesLoadedOnce || _segment == 0) {
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
      final res = await sl<ApiClient>().account(showSuccessSnack: false).post(URLs.labPackagesUrl, data: {if (pincode != null && pincode.isNotEmpty) 'pincode': pincode}, options: _auth());
      final data = (res.data is Map) ? res.data['data'] : null;
      final list = (data is Map && data['packages'] is List) ? data['packages'] as List : const [];
      final usedPincode = (data is Map ? data['pincode'] : null)?.toString() ?? '';
      final fallback = (data is Map && data['fallback'] is Map) ? data['fallback'] as Map : null;
      final fallbackList = (fallback != null && fallback['packages'] is List) ? fallback['packages'] as List : const [];
      final fallbackHospital = (fallback != null && fallback['hospital'] is Map) ? fallback['hospital'] as Map : null;
      if (!mounted) return;
      setState(() {
        _packagesLoadedOnce = true;
        _packages = list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        _fallbackPackages = fallbackList.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        _fallbackHospitalName = fallbackHospital?['name']?.toString() ?? '';
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

  /// First open of the tab: the pincode of where the patient is now, else the server falls back
  /// to the pincode of their saved address.
  Future<void> _firstLoad() async {
    _firstLoadStarted = true;
    if (_pincodeController.text.trim().isNotEmpty) {
      await _loadPackages(pincode: _pincodeController.text.trim());
      return;
    }
    setState(() => _loadingPackages = true);
    final found = await _locatePincode(interactive: false);
    if (!mounted) return;
    if (found != null) {
      _applyLocatedPincode(found);
    } else {
      await _loadPackages();
    }
  }

  /// The location icon in the pincode field: always asks, and says why when it can't.
  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    FocusScope.of(context).unfocus();
    final found = await _locatePincode(interactive: true);
    if (!mounted || found == null) return;
    _applyLocatedPincode(found);
  }

  void _applyLocatedPincode(({String pincode, String label}) found) {
    setState(() {
      _pincodeController.text = found.pincode;
      _locationLabel = found.label.isEmpty ? null : found.label;
    });
    _loadPackages(pincode: found.pincode);
  }

  /// The device's position turned into a 6-digit pincode and an area name. [interactive] shows a
  /// message (and the way to settings) when location is off or not allowed; the automatic first
  /// try stays quiet and lets the saved address be used instead.
  Future<({String pincode, String label})?> _locatePincode({required bool interactive}) async {
    setState(() => _locating = true);
    void tell(String message, {SnackBarAction? action}) {
      if (!interactive || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), action: action));
    }

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        tell(
          'Turn on location to find packages near you.',
          action: SnackBarAction(label: 'Settings', onPressed: () => Geolocator.openLocationSettings()),
        );
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        tell(
          'Location access is off for this app. Allow it in settings, or type your pincode.',
          action: SnackBarAction(label: 'Settings', onPressed: () => Geolocator.openAppSettings()),
        );
        return null;
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.unableToDetermine) {
        tell('Allow location access to find your pincode, or type it.');
        return null;
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
        );
      } catch (_) {
        // no fix in time (indoors, GPS warming up): the last known position is close enough for a pincode
        position = await Geolocator.getLastKnownPosition();
      }
      if (position == null) {
        tell('Could not find your location. Type your pincode instead.');
        return null;
      }

      final places = await geo.Geocoding().placemarkFromCoordinates(position.latitude, position.longitude).timeout(const Duration(seconds: 10));
      for (final place in places) {
        final pin = (place.postalCode ?? '').replaceAll(RegExp(r'\s'), '');
        if (RegExp(r'^[1-9]\d{5}$').hasMatch(pin)) {
          final label = {place.subLocality, place.locality}.map((s) => (s ?? '').trim()).where((s) => s.isNotEmpty).join(', ');
          return (pincode: pin, label: label);
        }
      }
      tell('Could not find the pincode for your location. Type it instead.');
      return null;
    } catch (_) {
      tell('Could not find your location. Type your pincode instead.');
      return null;
    } finally {
      if (mounted) setState(() => _locating = false);
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

  /// The package opens on its own page (details, then booking); it returns the order number once paid.
  Future<void> _openPackage(Map<String, dynamic> pkg) async {
    final booked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _LabPackageDetailsPage(package: pkg, pincode: _pincodeController.text.trim()),
      ),
    );
    if (booked != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(backgroundColor: _accent, content: Text(booked.isNotEmpty ? 'Payment successful. Order $booked is booked.' : 'Payment successful. Your lab package is booked.')));
      _switchSegment(1);
      _loadOrders();
    }
  }

  /// Pick or move the visit slot of a paid order; the sheet saves it and returns the updated order.
  Future<void> _changeSlot(Map<String, dynamic> order) async {
    final slot = order['slot'] is Map ? order['slot'] as Map : null;
    final updated = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotPickerSheet(orderId: order['id']?.toString(), currentDate: slot?['date']?.toString(), currentStart: slot?['start']?.toString()),
    );
    if (updated == null || !mounted) return;
    setState(() => _orders = _orders.map((o) => o['id'] == updated['id'] ? updated : o).toList());
    final booked = updated['slot'] is Map ? updated['slot'] as Map : null;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(backgroundColor: _accent, content: Text(booked != null ? 'Visit booked: ${_slotDay(booked['date']?.toString())}, ${booked['label']}' : 'Visit slot saved.')));
  }

  Future<void> _openReport(Map<String, dynamic> order) async {
    final id = order['id']?.toString() ?? '';
    if (id.isEmpty) return;
    setState(() => _openingReportFor = id);
    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).get('${URLs.labPackageOrdersUrl}/$id/report', options: _auth().copyWith(responseType: ResponseType.bytes));
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
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Packages',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 22, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF121212)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SegmentSwitch(labels: const ['Packages', 'My Orders'], selected: _segment, onChanged: _switchSegment, isDark: isDark),
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
                  // a typed pincode is no longer "your current location"
                  onChanged: (_) {
                    if (_locationLabel != null) setState(() => _locationLabel = null);
                  },
                  style: const TextStyle(fontFamily: appPoppinFont, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Your pincode',
                    prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                    suffixIcon: _locating
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : IconButton(
                            tooltip: 'Use my current location',
                            icon: const Icon(Icons.my_location, size: 20, color: _primary),
                            onPressed: _loadingPackages ? null : _useCurrentLocation,
                          ),
                    isDense: true,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF232323) : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loadingPackages ? null : _searchPincode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  // the app theme's buttons are full width (Size(infinity, 54)); inside this Row that
                  // has no width to fill and breaks the whole tab's layout
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Search',
                  style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        if (_locationLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 16, 0),
            child: Row(
              children: [
                const Icon(Icons.near_me, size: 14, color: _accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Your current location · $_locationLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF4A4A4A)),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadPackages(pincode: _pincodeController.text.trim()),
            child: _loadingPackages || (_locating && !_packagesLoadedOnce)
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        if (_locating) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Finding your location…',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                  )
                : _packagesError != null
                ? _messageList(Icons.error_outline, _packagesError!, isDark)
                : _packages.isEmpty && _fallbackPackages.isNotEmpty
                ? _buildFallback(isDark)
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
                onChangeSlot: () => _changeSlot(_orders[i]),
              ),
            ),
    );
  }

  /// No package in the pincode: say so, then list the default hospital's packages below.
  Widget _buildFallback(bool isDark) {
    final pin = _pincodeController.text.trim();
    final hospital = _fallbackHospitalName.isNotEmpty ? _fallbackHospitalName : 'our hospital';
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232323) : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 18, color: isDark ? Colors.amber.shade200 : const Color(0xFFB45309)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  pin.isEmpty
                      ? 'Add your pincode to see packages near you. Meanwhile, here are the packages from $hospital.'
                      : 'No lab packages near pincode $pin yet. You can still book these packages from $hospital.',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, height: 1.4, color: isDark ? Colors.white70 : const Color(0xFF78350F)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.local_hospital_outlined, size: 18, color: _primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Packages from $hospital',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF121212)),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 24, top: 2, bottom: 10),
          child: Text(
            'Bookable from any pincode',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: muted),
          ),
        ),
        for (final pkg in _fallbackPackages) ...[_PackageCard(pkg: pkg, isDark: isDark, onTap: () => _openPackage(pkg)), const SizedBox(height: 12)],
      ],
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
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: isDark ? Colors.white60 : Colors.grey.shade600),
        ),
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
      decoration: BoxDecoration(color: isDark ? const Color(0xFF232323) : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(color: active ? (isDark ? const Color(0xFF3A3A3A) : Colors.white) : Colors.transparent, borderRadius: BorderRadius.circular(9)),
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

/// A package in the list: its picture with the saving and report time on it, what it covers,
/// and the price with a way into the details page.
class _PackageCard extends StatelessWidget {
  final Map<String, dynamic> pkg;
  final bool isDark;
  final VoidCallback onTap;
  const _PackageCard({required this.pkg, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final groups = _testGroupsOf(pkg);
    final tests = groups.map((g) => (g['name'] ?? '').toString()).where((t) => t.trim().isNotEmpty).toList();
    final params = _num(pkg['parameterCount']).toInt();
    final offer = _num(pkg['price']);
    final original = pkg['mrp'] == null ? 0.0 : _num(pkg['mrp']);
    final off = _offPercent(original, offer);
    final gstPct = _num(pkg['gstPercentage']);
    final prep = (pkg['preparation'] ?? '').toString().trim();
    final turnaround = (pkg['reportTurnaround'] ?? '').toString().trim();
    final ink = isDark ? Colors.white : const Color(0xFF121212);
    final muted = isDark ? Colors.white60 : const Color(0xFF64748B);
    final line = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0);
    final look = labPackageLook(pkg);

    return Material(
      color: isDark ? const Color(0xFF232323) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'lab-package-${pkg['id']}',
                child: LabPackageCover(
                  package: pkg,
                  height: 132,
                  child: Stack(
                    children: [
                      if (off > 0) Positioned(top: 12, left: 12, child: _CoverPill(text: '$off% OFF', strong: true)),
                      Positioned(left: 12, bottom: 12, child: _CoverPill(text: look.label)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pkg['name']?.toString() ?? 'Lab package',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w700, color: ink, height: 1.25),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.biotech_outlined, size: 15, color: muted),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${tests.length} test${tests.length == 1 ? '' : 's'}${params > tests.length ? ' · $params parameters' : ''}'
                            '${turnaround.isNotEmpty ? ' · Report in $turnaround' : ''}',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: muted),
                          ),
                        ),
                      ],
                    ),
                    if (tests.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: [for (final t in tests.take(3)) _testChip(t), if (tests.length > 3) _testChip('+${tests.length - 3} more', highlight: true)]),
                    ],
                    if (prep.isNotEmpty || _num(pkg['benefitsValue']) > 0) const SizedBox(height: 10),
                    if (prep.isNotEmpty)
                      _infoLine(
                        _prepIsEasy(prep) ? Icons.check_circle_outline : Icons.no_food_outlined,
                        'Preparation: $prep',
                        _prepIsEasy(prep) ? (isDark ? Colors.white70 : const Color(0xFF475569)) : (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309)),
                      ),
                    if (_num(pkg['benefitsValue']) > 0)
                      _infoLine(
                        Icons.workspace_premium_outlined,
                        'Worth ${_rupees(_num(pkg['benefitsValue']))}${pkg['benefitsValuePlus'] == true ? '+' : ''} of care',
                        isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                        bold: true,
                      ),
                    const SizedBox(height: 12),
                    Divider(height: 1, color: line),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (off > 0)
                                Text(
                                  _money(original),
                                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: muted, decoration: TextDecoration.lineThrough),
                                ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    _priceLabel(offer),
                                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 21, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF93B4FF) : _primary),
                                  ),
                                  if (gstPct > 0 && offer > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '+ ${_pct(gstPct)}% GST',
                                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: muted),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 40),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View details',
                                style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _testChip(String text, {bool highlight = false}) {
    final blue = isDark ? const Color(0xFF93B4FF) : _accent;
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: highlight ? blue.withValues(alpha: isDark ? 0.16 : 0.08) : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: appPoppinFont,
          fontSize: 11.5,
          fontWeight: highlight ? FontWeight.w600 : FontWeight.w500,
          color: highlight ? blue : (isDark ? Colors.white70 : const Color(0xFF334155)),
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String text, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// A label on a package picture: white glass, readable on any cover or photo.
class _CoverPill extends StatelessWidget {
  final String text;
  final bool strong;
  const _CoverPill({required this.text, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: strong ? Colors.white : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: strong ? null : Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: strong ? FontWeight.w800 : FontWeight.w600, color: strong ? _accent : Colors.white),
          ),
        ],
      ),
    );
  }
}

/// Whole rupees with Indian grouping: ₹4,100
String _rupees(num value) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value.round());

/// Icon and colours of a "why it is worth it" card; the same set as the web admin's picker
const Map<String, IconData> _benefitIcons = {
  'lab': Icons.science_outlined,
  'doctor': Icons.medical_services_outlined,
  'report': Icons.description_outlined,
  'dental': Icons.sentiment_satisfied_alt_outlined,
  'eye': Icons.visibility_outlined,
  'insurance': Icons.health_and_safety_outlined,
  'home': Icons.home_outlined,
  'family': Icons.family_restroom_outlined,
  'support': Icons.support_agent_outlined,
  'heart': Icons.favorite_border,
  'calendar': Icons.event_available_outlined,
  'video': Icons.videocam_outlined,
};

/// Words in a benefit's title that name its icon, for benefits saved with the generic
/// 'lab' icon (or none): "Dental check-up" gets the dental icon, not a flask.
const List<(String, String)> _benefitKeywords = [
  ('dental', 'dental'),
  ('dentist', 'dental'),
  ('tooth', 'dental'),
  ('teeth', 'dental'),
  ('eye', 'eye'),
  ('vision', 'eye'),
  ('optic', 'eye'),
  ('insurance', 'insurance'),
  ('accident', 'insurance'),
  ('cover', 'insurance'),
  ('consult', 'doctor'),
  ('doctor', 'doctor'),
  ('physician', 'doctor'),
  ('report', 'report'),
  ('home', 'home'),
  ('family', 'family'),
  ('video', 'video'),
  ('heart', 'heart'),
  ('cardio', 'heart'),
  ('support', 'support'),
];

IconData _benefitIcon(Map benefit) {
  final key = benefit['icon']?.toString().trim().toLowerCase() ?? '';
  if (key.isNotEmpty && key != 'lab' && _benefitIcons.containsKey(key)) return _benefitIcons[key]!;
  final title = (benefit['title'] ?? '').toString().toLowerCase();
  for (final (word, icon) in _benefitKeywords) {
    if (title.contains(word)) return _benefitIcons[icon]!;
  }
  return _benefitIcons['lab']!;
}

/// A package's tests with their parameters: `testGroups` from the server, or (older packages) the
/// plain `tests` names, each then a single test.
List<Map<String, dynamic>> _testGroupsOf(Map<String, dynamic> pkg) {
  final groups = pkg['testGroups'];
  if (groups is List && groups.isNotEmpty) {
    return groups.whereType<Map>().map((g) => Map<String, dynamic>.from(g)).toList();
  }
  final tests = pkg['tests'] is List ? pkg['tests'] as List : const [];
  return tests.map((t) => <String, dynamic>{'name': t.toString(), 'description': '', 'tests': const <String>[]}).toList();
}

/// Badge colours (background, number) the test cards cycle through
const List<(Color, Color)> _testBadgeColors = [(Color(0xFFEAF0FE), _accent)];

/// "Tests included": a card per test with its parameter count, name and description; tapping +
/// opens the parameters in two columns, − closes them.
class _TestGroupCards extends StatefulWidget {
  final List<Map<String, dynamic>> groups;
  final bool isDark;
  const _TestGroupCards({required this.groups, required this.isDark});

  @override
  State<_TestGroupCards> createState() => _TestGroupCardsState();
}

class _TestGroupCardsState extends State<_TestGroupCards> {
  final Set<int> _open = {};

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final groups = widget.groups;
    final parameters = groups.fold<int>(0, (n, g) => n + ((g['tests'] is List && (g['tests'] as List).isNotEmpty) ? (g['tests'] as List).length : 1));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tests included',
          style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
        ),
        Text(
          '${groups.length} test${groups.length == 1 ? '' : 's'}${parameters > groups.length ? ' · $parameters parameters' : ''}',
          style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: subColor),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < groups.length; i++) _card(i, groups[i], textColor, subColor),
      ],
    );
  }

  Widget _card(int i, Map<String, dynamic> group, Color textColor, Color subColor) {
    final isDark = widget.isDark;
    final params = group['tests'] is List ? (group['tests'] as List).map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList() : <String>[];
    final description = (group['description'] ?? '').toString().trim();
    final canOpen = params.isNotEmpty;
    final open = canOpen && _open.contains(i);
    final (badgeBg, badgeFg) = _testBadgeColors[i % _testBadgeColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: canOpen ? () => setState(() => open ? _open.remove(i) : _open.add(i)) : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: isDark ? badgeFg.withValues(alpha: 0.2) : badgeBg, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      '${canOpen ? params.length : 1}',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 17, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF93B4FF) : badgeFg),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['name']?.toString() ?? '',
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        if (description.isNotEmpty)
                          Text(
                            description,
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: subColor),
                          ),
                      ],
                    ),
                  ),
                  if (canOpen) Icon(open ? Icons.remove : Icons.add, color: _accent, size: 22),
                ],
              ),
            ),
          ),
          if (open) ...[
            Divider(height: 1, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final column = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: params
                        .map(
                          (p) => SizedBox(
                            width: column,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: CircleAvatar(radius: 3, backgroundColor: _accent),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p,
                                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: textColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "WHY IT IS WORTH IT · ₹4,100+ of care for ₹1,299": each card with what it would cost if booked separately
class _WorthItSection extends StatelessWidget {
  final List<Map> benefits;
  final double pays;
  final bool isDark;
  const _WorthItSection({required this.benefits, required this.pays, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final total = benefits.fold<double>(0, (s, b) => s + _num(b['value']));
    final plus = benefits.any((b) => b['valuePlus'] == true);
    // Values marked "+" are estimates, so the saving is rounded down to a round figure.
    final saving = plus ? ((total - pays) / 100).floor() * 100.0 : total - pays;
    final accent = Theme.of(context).primaryColor;
    final ink = isDark ? Colors.white : const Color(0xFF111111);
    final muted = isDark ? Colors.white70 : const Color(0xFF5F6368);
    final card = isDark ? const Color(0xFF232323) : Colors.white;
    final line = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE6EAF0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'WHY IT IS WORTH IT',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: accent),
        ),
        if (total > 0) ...[
          const SizedBox(height: 6),
          Text(
            '${_rupees(total)}${plus ? '+' : ''} of care for ${_rupees(pays)}',
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 21, fontWeight: FontWeight.w700, color: ink, height: 1.25),
          ),
          if (saving > 0) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.2 : 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'You save ${_rupees(saving)}${plus ? '+' : ''}',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF93B4FF) : accent),
                ),
              ),
            ),
          ],
        ],
        const SizedBox(height: 8),
        Text(
          'What each would typically cost if booked on its own.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: muted),
        ),
        const SizedBox(height: 14),
        Container(
          decoration: BoxDecoration(
            color: card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: line),
          ),
          child: Column(
            children: [
              for (final (i, b) in benefits.indexed) ...[if (i > 0) Divider(height: 1, thickness: 1, indent: 66, color: line), _benefitRow(b, accent: accent, ink: ink, muted: muted)],
            ],
          ),
        ),
      ],
    );
  }

  Widget _benefitRow(Map b, {required Color accent, required Color ink, required Color muted}) {
    final value = _num(b['value']);
    final description = (b['description'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_benefitIcon(b), color: isDark ? const Color(0xFF93B4FF) : accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (b['title'] ?? '').toString(),
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w600, color: ink, height: 1.3),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: muted, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
          if (value > 0) ...[
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_rupees(value)}${b['valuePlus'] == true ? '+' : ''}',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.w700, color: ink),
                ),
                Text(
                  'value',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, color: muted),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final bool isDark;
  final bool openingReport;
  final VoidCallback onViewReport;
  final VoidCallback onChangeSlot;
  const _OrderCard({required this.order, required this.isDark, required this.openingReport, required this.onViewReport, required this.onChangeSlot});

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
    final slot = order['slot'] is Map ? order['slot'] as Map : null;
    final canChangeSlot = order['canChangeSlot'] == true;
    final changeUntil = DateTime.tryParse(order['slotChangeUntil']?.toString() ?? '')?.toLocal();
    final lockedReason = order['slotLockedReason']?.toString();
    final showSlot = slot != null || status == 'Paid';
    final muted = isDark ? Colors.white54 : Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order['packageName']?.toString() ?? 'Lab package',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF121212)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  order['statusLabel']?.toString() ?? status,
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            order['hospitalName']?.toString() ?? '',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF4A4A4A)),
          ),
          const SizedBox(height: 2),
          Text(
            '${order['orderNumber'] ?? ''}${created != null ? ' · ${DateFormat('dd MMM yyyy').format(created)}' : ''}${slot == null && preferred != null && preferred.isNotEmpty ? ' · Visit ${_formatDay(preferred)}' : ''}',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: muted),
          ),
          if (order['collectionAddress'] is Map && ((order['collectionAddress'] as Map)['text'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    (order['collectionAddress'] as Map)['text'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: muted),
                  ),
                ),
              ],
            ),
          ],
          if (showSlot) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
              decoration: BoxDecoration(
                color: slot != null ? _primary.withValues(alpha: isDark ? 0.15 : 0.06) : const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(slot != null ? Icons.event_available : Icons.event_outlined, size: 20, color: slot != null ? _primary : const Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot != null ? '${_slotDay(slot['date']?.toString())} · ${slot['label']}' : 'No visit slot chosen yet',
                          style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF121212)),
                        ),
                        if (slot != null && canChangeSlot && changeUntil != null)
                          Text(
                            'You can change it until ${DateFormat('hh:mm a, dd MMM').format(changeUntil)}',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, color: muted),
                          )
                        else if (slot == null && canChangeSlot)
                          Text(
                            'Choose when to visit the hospital for your sample.',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, color: muted),
                          )
                        else if (!canChangeSlot && status == 'Paid' && lockedReason != null)
                          Text(
                            lockedReason,
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 10.5, color: muted),
                          ),
                      ],
                    ),
                  ),
                  if (canChangeSlot)
                    TextButton(
                      onPressed: onChangeSlot,
                      child: Text(
                        slot == null ? 'Choose' : 'Reschedule',
                        style: const TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                _money(_num(order['totalAmount'])),
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF121212)),
              ),
              const SizedBox(width: 6),
              Text(
                'paid',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
              ),
              const Spacer(),
              if ((order['invoiceUrl'] ?? '').toString().startsWith('https://'))
                TextButton.icon(
                  key: const Key('labOrder.invoice'),
                  onPressed: () => openWalletFile(
                    context,
                    order['invoiceUrl'].toString(),
                    title: 'Invoice ${order['invoiceNumber'] ?? order['orderNumber'] ?? ''}'.trim(),
                    category: 'Invoice',
                  ),
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('Invoice', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600)),
                ),
              if (hasReport)
                TextButton.icon(
                  onPressed: openingReport ? null : onViewReport,
                  icon: openingReport ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.description_outlined, size: 18),
                  label: const Text(
                    'View report',
                    style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
                  ),
                )
              else if (status != 'Cancelled')
                Text(
                  'Report pending',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: isDark ? Colors.white54 : Colors.grey.shade600),
                ),
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

/// A package's own page: its picture, what it covers and why it is worth it, then booking: the
/// collection address, an optional visit slot and notes, the price with GST, and Pay (the nearest
/// hospital's own Razorpay account takes the payment). Pops with the order number once paid.
class _LabPackageDetailsPage extends StatefulWidget {
  final Map<String, dynamic> package;
  final String pincode;

  /// Tests only: the hospitals to show instead of loading them
  final List<Map<String, dynamic>>? hospitals;

  /// The second step, opened by Book now: address, visit slot, notes, price and Pay.
  final bool checkout;
  const _LabPackageDetailsPage({required this.package, required this.pincode, this.hospitals, this.checkout = false});

  @override
  State<_LabPackageDetailsPage> createState() => _LabPackageDetailsPageState();
}

class _LabPackageDetailsPageState extends State<_LabPackageDetailsPage> {
  bool _loadingHospitals = true;
  String? _hospitalsError;
  List<Map<String, dynamic>> _hospitals = [];
  int? _hospitalId;

  /// Optional at checkout; it can also be chosen from My Orders after paying
  _SlotChoice? _slot;

  /// Where the sample is collected; every order needs one
  LabCollectionAddress? _address;
  final TextEditingController _notesController = TextEditingController();
  bool _paying = false;
  String? _payError;

  @override
  void initState() {
    super.initState();
    if (widget.checkout) _loadHospitals();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  /// The collection address's pincode once there is one, else the pincode the patient searched.
  String get _pincode => _address?.pincode ?? widget.pincode;

  Future<void> _loadHospitals() async {
    if (widget.hospitals != null) {
      setState(() {
        _hospitals = widget.hospitals!;
        _hospitalId = _hospitals.isEmpty ? null : int.tryParse(_hospitals.first['id'].toString());
        _loadingHospitals = false;
      });
      return;
    }
    try {
      final res = await sl<ApiClient>()
          .account(showSuccessSnack: false)
          .post(URLs.labPackageHospitalsUrl, data: {'packageId': widget.package['id'], if (_pincode.isNotEmpty) 'pincode': _pincode}, options: _auth());
      final data = (res.data is Map) ? res.data['data'] : null;
      if (!mounted) return;
      setState(() {
        _hospitals = (data is List ? data : const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        // No hospital choice in the sheet: the server lists those in the patient's pincode first
        if (_hospitals.isNotEmpty) _hospitalId = int.tryParse(_hospitals.first['id'].toString());
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hospitalsError = _errorText(e, 'Could not load hospitals for this package.'));
    } finally {
      if (mounted) setState(() => _loadingHospitals = false);
    }
  }

  /// Book now: the second step collects the address, slot and notes, and pays.
  Future<void> _openCheckout() async {
    final booked = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _LabPackageDetailsPage(package: widget.package, pincode: widget.pincode, hospitals: widget.hospitals, checkout: true),
      ),
    );
    if (booked != null && mounted) Navigator.of(context).pop(booked);
  }

  /// The chosen hospital's visit slots (its timings from Lab Package Orders → Settings).
  Future<void> _pickSlot() async {
    if (_hospitalId == null) {
      setState(() => _payError = _loadingHospitals ? 'Please wait a moment and try again.' : 'This package cannot be booked online right now.');
      return;
    }
    final choice = await showModalBottomSheet<_SlotChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SlotPickerSheet(hospitalId: _hospitalId, currentDate: _slot?.date, currentStart: _slot?.start),
    );
    if (choice != null && mounted) {
      setState(() {
        _slot = choice;
        _payError = null;
      });
    }
  }

  Future<void> _pickAddress() async {
    final picked = await LabAddressPickerSheet.show(context, current: _address, pincode: _pincode);
    if (picked == null || !mounted) return;
    final pincodeChanged = picked.pincode != _pincode;
    setState(() {
      _address = picked;
      _payError = null;
      if (pincodeChanged) {
        // Hospitals near the new pincode come first; the slot belongs to the old hospital.
        _loadingHospitals = true;
        _hospitalsError = null;
        _hospitals = [];
        _hospitalId = null;
        _slot = null;
      }
    });
    if (pincodeChanged) await _loadHospitals();
  }

  Future<void> _pay() async {
    if (_address == null) {
      setState(() => _payError = 'Add the address where your sample will be collected.');
      _pickAddress();
      return;
    }
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
      pincode: _pincode,
      address: _address!.toJson(),
      preferredDate: _slot?.date,
      slotStart: _slot?.start,
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

  /// The collection address, or a prompt to add one.
  Widget _addressTile(bool isDark, Color textColor, Color subColor) {
    final a = _address;
    final line = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD7DCE3);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _paying ? null : _pickAddress,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: a == null && _payError != null ? Colors.red : line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 20, color: a == null ? (isDark ? const Color(0xFF93B4FF) : _accent) : textColor),
              const SizedBox(width: 10),
              Expanded(
                child: a == null
                    ? Text(
                        'Add sample collection address *',
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF93B4FF) : _accent),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sample collection address',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: subColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.text,
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.w500, color: textColor, height: 1.35),
                          ),
                        ],
                      ),
              ),
              if (a != null) ...[
                const SizedBox(width: 8),
                Text(
                  'Change',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF93B4FF) : _accent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pkg = widget.package;
    final price = _num(pkg['price']);
    final original = pkg['mrp'] == null ? 0.0 : _num(pkg['mrp']);
    final off = _offPercent(original, price);
    final gstPct = _num(pkg['gstPercentage']);
    final gst = _num(pkg['gstAmount']);
    final total = _num(pkg['totalAmount']);
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    final look = labPackageLook(pkg);
    final turnaround = (pkg['reportTurnaround'] ?? '').toString().trim();
    final groups = _testGroupsOf(pkg);
    final params = _num(pkg['parameterCount']).toInt();
    final pageBg = isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF232323) : Colors.white;
    final line = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E8F0);

    Widget section(String title, List<Widget> children) => Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
            ),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );

    if (widget.checkout) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: cardBg,
          surfaceTintColor: Colors.transparent,
          foregroundColor: textColor,
          elevation: 0,
          title: Text(
            'Book package',
            style: TextStyle(fontFamily: appPoppinFont, fontSize: 17, fontWeight: FontWeight.w700, color: textColor),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            // What is being booked
            Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  SizedBox(width: 92, height: 92, child: LabPackageCover(package: pkg, height: 92)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pkg['name']?.toString() ?? 'Lab package',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700, color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${groups.length} test${groups.length == 1 ? '' : 's'}${turnaround.isNotEmpty ? ' · Report in $turnaround' : ''}',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: subColor),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _priceLabel(total),
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF93B4FF) : _primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            section('Book this package', [
              // The hospital is picked for the patient (no choice shown); only say when booking is not possible
              if (_hospitalsError != null) ...[
                Text(
                  _hospitalsError!,
                  style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.red),
                ),
                const SizedBox(height: 10),
              ] else if (!_loadingHospitals && _hospitals.isEmpty) ...[
                Text(
                  'This package cannot be booked online right now.',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: subColor),
                ),
                const SizedBox(height: 10),
              ],
              _addressTile(isDark, textColor, subColor),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _paying ? null : _pickSlot,
                icon: Icon(_slot == null ? Icons.event_outlined : Icons.event_available, size: 18),
                label: Text(_slot == null ? 'Choose visit slot (optional)' : 'Visit ${_slotDay(_slot!.date)} · ${_slot!.label}', style: const TextStyle(fontFamily: appPoppinFont)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? const Color(0xFF93B4FF) : _accent,
                  side: BorderSide(color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD7DCE3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  alignment: Alignment.centerLeft,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Text(
                  'You can also choose or change it later in My Orders, until 5 hours before the slot.',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: subColor),
                ),
              ),
              const SizedBox(height: 12),
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
            ]),
            section('Price details', [
              if (off > 0) ...[
                Row(
                  children: [
                    Text(
                      'Original price',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: subColor),
                    ),
                    const Spacer(),
                    Text(
                      _money(original),
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: subColor, decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              _priceRow(off > 0 ? 'Offer price ($off% off)' : 'Package price', _money(price), subColor, textColor),
              const SizedBox(height: 6),
              _priceRow('GST (${_pct(gstPct)}%)', _money(gst), subColor, textColor),
              Divider(height: 20, color: line),
              _priceRow('Total', _money(total), textColor, textColor, bold: true),
              if (off > 0) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'You save ${_money(original - price)}',
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857)),
                  ),
                ),
              ],
            ]),
            if (_payError != null) ...[
              const SizedBox(height: 12),
              Text(
                _payError!,
                style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: Colors.red),
              ),
            ],
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: cardBg,
            border: Border(top: BorderSide(color: line)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _priceLabel(total),
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      Text(
                        total <= 0 ? 'Nothing to pay' : gstPct > 0 ? 'incl. ${_pct(gstPct)}% GST' : 'Total to pay',
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: subColor),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton(
                      key: const Key('labPackage.pay'),
                      onPressed: (_paying || _loadingHospitals || _hospitals.isEmpty) ? null : _pay,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _paying
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(
                              total > 0 ? 'Pay ${_money(total)}' : 'Confirm booking',
                              style: const TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 250,
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : _primary,
            foregroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            // white status bar icons over the coloured cover
            systemOverlayStyle: SystemUiOverlayStyle.light,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: Material(
                color: Colors.black.withValues(alpha: 0.22),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, box) {
                final collapsed = box.maxHeight <= kToolbarHeight + MediaQuery.paddingOf(context).top + 8;
                return FlexibleSpaceBar(
                  titlePadding: const EdgeInsetsDirectional.only(start: 64, end: 16, bottom: 16),
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: collapsed ? 1 : 0,
                    child: Text(
                      pkg['name']?.toString() ?? 'Lab package',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontFamily: appPoppinFont, fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  background: Hero(
                    tag: 'lab-package-${pkg['id']}',
                    child: LabPackageCover(
                      package: pkg,
                      height: 250 + MediaQuery.paddingOf(context).top,
                      large: true,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 20,
                            bottom: 18,
                            child: Row(
                              children: [
                                _CoverPill(text: look.label),
                                if (off > 0) ...[const SizedBox(width: 8), _CoverPill(text: '$off% OFF', strong: true)],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList.list(
              children: [
                Text(
                  pkg['name']?.toString() ?? 'Lab package',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 21, fontWeight: FontWeight.w700, color: textColor, height: 1.25),
                ),
                const SizedBox(height: 4),
                Text(
                  '${groups.length} test${groups.length == 1 ? '' : 's'}${params > groups.length ? ' · $params parameters' : ''}${turnaround.isNotEmpty ? ' · Report in $turnaround' : ''}',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: subColor),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _priceLabel(price),
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 26, fontWeight: FontWeight.w800, color: isDark ? const Color(0xFF93B4FF) : _primary),
                    ),
                    if (off > 0) ...[
                      const SizedBox(width: 10),
                      Text(
                        _money(original),
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: subColor, decoration: TextDecoration.lineThrough),
                      ),
                    ],
                    if (gstPct > 0 && price > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '+ ${_pct(gstPct)}% GST',
                        style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, color: subColor),
                      ),
                    ],
                  ],
                ),
                if ((pkg['description'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    pkg['description'].toString(),
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: subColor, height: 1.45),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if ((pkg['sampleType'] ?? '').toString().isNotEmpty) _chip(Icons.water_drop_outlined, pkg['sampleType'].toString(), isDark),
                    if (turnaround.isNotEmpty) _chip(Icons.schedule, 'Report in $turnaround', isDark),
                    if ((pkg['preparation'] ?? '').toString().isNotEmpty)
                        _chip(_prepIsEasy(pkg['preparation'].toString()) ? Icons.check_circle_outline : Icons.no_food_outlined, 'Preparation: ${pkg['preparation']}', isDark),
                    _chip(Icons.home_outlined, 'Sample collected at home', isDark),
                  ],
                ),
                if (pkg['benefits'] is List && (pkg['benefits'] as List).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 22),
                    child: _WorthItSection(benefits: (pkg['benefits'] as List).whereType<Map>().toList(), pays: total, isDark: isDark),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: _TestGroupCards(groups: groups, isDark: isDark),
                ),
              ],
            ),
          ),
        ],
      ),
      // Total and Pay stay in reach while reading the details
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBg,
          border: Border(top: BorderSide(color: line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _priceLabel(total),
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                    ),
                    Text(
                      total <= 0 ? 'Nothing to pay' : gstPct > 0 ? 'incl. ${_pct(gstPct)}% GST' : 'Total to pay',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: subColor),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('labPackage.bookNow'),
                    onPressed: _openCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 50),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Book now',
                      style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF232323) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white70 : const Color(0xFF4A4A4A)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF4A4A4A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, Color labelColor, Color valueColor, {bool bold = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(fontFamily: appPoppinFont, fontSize: bold ? 15 : 13, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: labelColor),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontFamily: appPoppinFont, fontSize: bold ? 16 : 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: valueColor),
        ),
      ],
    );
  }
}

/// A visit slot chosen at checkout, before there is an order: "YYYY-MM-DD", "HH:mm" and its label.
typedef _SlotChoice = ({String date, String start, String label});

/// The hospital's bookable visit slots by day (its timings from Lab Package Orders → Settings, 10 AM –
/// 6 PM by default), starting 5+ hours from now. With [orderId] the chosen slot is saved to the paid
/// order and the sheet pops with the updated order; with [hospitalId] (checkout) it pops a [_SlotChoice].
class _SlotPickerSheet extends StatefulWidget {
  final String? orderId;
  final int? hospitalId;
  final String? currentDate;
  final String? currentStart;
  const _SlotPickerSheet({this.orderId, this.hospitalId, this.currentDate, this.currentStart});

  @override
  State<_SlotPickerSheet> createState() => _SlotPickerSheetState();
}

class _SlotPickerSheetState extends State<_SlotPickerSheet> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _days = [];
  int _cutoffHours = 5;
  String? _date;
  String? _start;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Map<String, dynamic>> _slotsOf(String? date) {
    final day = _days.where((d) => d['date']?.toString() == date).firstOrNull;
    final slots = day?['slots'];
    return slots is List ? slots.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList() : [];
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await sl<ApiClient>()
          .account(showSuccessSnack: false)
          .post(URLs.labPackageSlotsUrl, data: widget.orderId != null ? {'orderId': widget.orderId} : {'hospitalId': widget.hospitalId}, options: _auth());
      final data = (res.data is Map) ? res.data['data'] : null;
      final days = (data is Map && data['days'] is List) ? data['days'] as List : const [];
      if (!mounted) return;
      setState(() {
        _days = days.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
        _cutoffHours = int.tryParse('${data is Map ? data['cutoffHours'] : ''}') ?? 5;
        // start on the booked slot's day when it is still open, else the first open day
        _date = _days.any((d) => d['date'] == widget.currentDate) ? widget.currentDate : (_days.isNotEmpty ? _days.first['date']?.toString() : null);
        _start = _slotsOf(_date).any((s) => s['start'] == widget.currentStart) ? widget.currentStart : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _errorText(e, 'Could not load the visit slots. Try again.'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirm() async {
    final date = _date, start = _start;
    if (date == null || start == null) return;
    final label = _slotsOf(date).firstWhere((s) => s['start'] == start, orElse: () => {'label': start})['label'].toString();
    if (widget.orderId == null) {
      Navigator.of(context).pop<_SlotChoice>((date: date, start: start, label: label));
      return;
    }
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final res = await sl<ApiClient>().account(showSuccessSnack: false).post('${URLs.labPackageOrdersUrl}/${widget.orderId}/slot', data: {'date': date, 'slotStart': start}, options: _auth());
      final data = (res.data is Map) ? res.data['data'] : null;
      if (!mounted) return;
      if (data is Map) {
        Navigator.of(context).pop(Map<String, dynamic>.from(data));
      } else {
        setState(() => _saveError = 'Could not save the slot. Try again.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveError = _errorText(e, 'Could not save the slot. Try again.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF121212);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final rescheduling = widget.currentStart != null;
    final unchanged = _date == widget.currentDate && _start == widget.currentStart;
    final slots = _slotsOf(_date);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                rescheduling ? 'Reschedule your visit' : 'Choose a visit slot',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
              ),
              const SizedBox(height: 4),
              Text(
                'You can change it until $_cutoffHours hours before the slot.',
                style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: subColor),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: Colors.red),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Try again', style: TextStyle(fontFamily: appPoppinFont)),
                      ),
                    ],
                  ),
                )
              else if (_days.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No visit slots are open in the next 14 days. Please call the hospital.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: subColor),
                  ),
                )
              else ...[
                SizedBox(
                  height: 74,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _days.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final date = _days[i]['date']?.toString();
                      final d = DateTime.tryParse(date ?? '');
                      final selected = date == _date;
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _saving
                            ? null
                            : () => setState(() {
                                _date = date;
                                if (!_slotsOf(date).any((s) => s['start'] == _start)) _start = null;
                              }),
                        child: Container(
                          width: 58,
                          decoration: BoxDecoration(color: selected ? _primary : (isDark ? const Color(0xFF232323) : const Color(0xFFF1F5F9)), borderRadius: BorderRadius.circular(14)),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                d != null ? DateFormat('EEE').format(d) : '',
                                style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: selected ? Colors.white70 : subColor),
                              ),
                              Text(
                                d != null ? DateFormat('dd').format(d) : (date ?? ''),
                                style: TextStyle(fontFamily: appPoppinFont, fontSize: 18, fontWeight: FontWeight.w700, color: selected ? Colors.white : textColor),
                              ),
                              Text(
                                d != null ? DateFormat('MMM').format(d) : '',
                                style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, color: selected ? Colors.white70 : subColor),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Time',
                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.map((s) {
                        final selected = s['start'] == _start;
                        return ChoiceChip(
                          label: Text(
                            s['label']?.toString() ?? '',
                            style: TextStyle(fontFamily: appPoppinFont, fontSize: 12.5, color: selected ? Colors.white : textColor),
                          ),
                          selected: selected,
                          selectedColor: _primary,
                          showCheckmark: false,
                          onSelected: _saving ? null : (_) => setState(() => _start = s['start']?.toString()),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _saveError!,
                  style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.red),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_saving || _loading || _date == null || _start == null || unchanged) ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          rescheduling ? 'Reschedule' : 'Confirm slot',
                          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tests only: a package card and a package's page, without the network.
@visibleForTesting
Widget labPackageCardForTest(Map<String, dynamic> pkg, {bool isDark = false}) => _PackageCard(pkg: pkg, isDark: isDark, onTap: () {});

@visibleForTesting
Widget labPackageDetailsForTest(Map<String, dynamic> pkg, {bool checkout = false}) => _LabPackageDetailsPage(
  package: pkg,
  pincode: '500072',
  hospitals: const [
    {'id': 19, 'name': 'Yira Hospitals'},
  ],
  checkout: checkout,
);
