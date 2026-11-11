import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/local/global_session.dart';
import '../../../../core/urls/urls.dart';
import '../../../../di/dependency_injection.dart';

/// Where a lab sample is collected. Same fields and rules as the server
/// (lab-address.ts): house and street, city and a 6-digit pincode are required.
class LabCollectionAddress {
  final String label;
  final String line1;
  final String line2;
  final String landmark;
  final String city;
  final String state;
  final String pincode;

  const LabCollectionAddress({
    this.label = '',
    required this.line1,
    this.line2 = '',
    this.landmark = '',
    required this.city,
    this.state = '',
    required this.pincode,
  });

  factory LabCollectionAddress.fromJson(Map<String, dynamic> j) {
    String s(String k) => (j[k] ?? '').toString().trim();
    return LabCollectionAddress(
      label: s('label'),
      line1: s('line1'),
      line2: s('line2'),
      landmark: s('landmark'),
      city: s('city'),
      state: s('state'),
      pincode: s('pincode').replaceAll(RegExp(r'\D'), ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'line1': line1,
        if (line2.isNotEmpty) 'line2': line2,
        if (landmark.isNotEmpty) 'landmark': landmark,
        'city': city,
        if (state.isNotEmpty) 'state': state,
        'pincode': pincode,
      };

  /// "12 MG Road, Indiranagar, Near Metro, Bengaluru, Karnataka 560038"
  String get text {
    final place = [city, state].where((e) => e.isNotEmpty).join(', ');
    return [line1, line2, landmark, '$place $pincode'.trim()].where((e) => e.isNotEmpty).join(', ');
  }

  /// The first thing missing, or null when the server will accept it.
  String? get problem {
    if (line1.trim().isEmpty) return 'Enter the house number and street.';
    if (city.trim().isEmpty) return 'Enter the city.';
    if (!RegExp(r'^\d{6}$').hasMatch(pincode)) return 'Enter a 6-digit pincode.';
    return null;
  }
}

/// Addresses the patient used before or saved on their profile.
Future<List<LabCollectionAddress>> fetchSavedLabAddresses() async {
  final token = GlobalSession.instance.userNotifier.value?.data?.accessToken ?? '';
  final res = await sl<ApiClient>().account(showSuccessSnack: false).post(
        URLs.labPackageAddressesUrl,
        data: const {},
        options: Options(
          extra: const {'suppressErrorSnack': true},
          headers: {if (token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );
  final data = res.data is Map ? res.data['data'] : null;
  return (data is List ? data : const [])
      .whereType<Map>()
      .map((m) => LabCollectionAddress.fromJson(Map<String, dynamic>.from(m)))
      .where((a) => a.problem == null)
      .toList();
}

/// Picks a saved address or takes a new one. Pops with the chosen address.
class LabAddressPickerSheet extends StatefulWidget {
  final LabCollectionAddress? current;
  final String pincode;

  /// For tests: skip loading and show these.
  final List<LabCollectionAddress>? saved;

  const LabAddressPickerSheet({super.key, this.current, this.pincode = '', this.saved});

  static Future<LabCollectionAddress?> show(BuildContext context, {LabCollectionAddress? current, String pincode = ''}) =>
      showModalBottomSheet<LabCollectionAddress>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => LabAddressPickerSheet(current: current, pincode: pincode),
      );

  @override
  State<LabAddressPickerSheet> createState() => _LabAddressPickerSheetState();
}

class _LabAddressPickerSheetState extends State<LabAddressPickerSheet> {
  List<LabCollectionAddress>? _saved;
  bool _adding = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _line1 = TextEditingController(text: widget.current?.line1 ?? '');
  late final TextEditingController _line2 = TextEditingController(text: widget.current?.line2 ?? '');
  late final TextEditingController _landmark = TextEditingController(text: widget.current?.landmark ?? '');
  late final TextEditingController _city = TextEditingController(text: widget.current?.city ?? '');
  late final TextEditingController _state = TextEditingController(text: widget.current?.state ?? '');
  late final TextEditingController _pincode =
      TextEditingController(text: widget.current?.pincode ?? (RegExp(r'^\d{6}$').hasMatch(widget.pincode) ? widget.pincode : ''));

  @override
  void initState() {
    super.initState();
    if (widget.saved != null) {
      _saved = widget.saved;
      _adding = widget.saved!.isEmpty;
    } else {
      _load();
    }
  }

  @override
  void dispose() {
    for (final c in [_line1, _line2, _landmark, _city, _state, _pincode]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final saved = await fetchSavedLabAddresses();
      if (!mounted) return;
      setState(() {
        _saved = saved;
        if (saved.isEmpty) _adding = true;
      });
    } catch (_) {
      // Saved addresses are a shortcut; the patient can still type one.
      if (mounted) {
        setState(() {
          _saved = const [];
          _adding = true;
        });
      }
    }
  }

  void _useTyped() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final address = LabCollectionAddress(
      line1: _line1.text.trim(),
      line2: _line2.text.trim(),
      landmark: _landmark.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      pincode: _pincode.text.trim(),
    );
    final problem = address.problem;
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? Colors.white : const Color(0xFF111111);
    final muted = isDark ? Colors.white60 : const Color(0xFF6B6B6B);
    final card = isDark ? const Color(0xFF232323) : const Color(0xFFF6F7F9);
    final line = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE2E2E2);
    const blue = Color(0xFF2563EB);
    final saved = _saved;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 16),
              Text('Sample collection address', style: TextStyle(fontFamily: appPoppinFont, fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
              const SizedBox(height: 4),
              Text('Where should the lab collect your sample?', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: muted)),
              const SizedBox(height: 16),
              if (saved == null)
                const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
              else ...[
                for (final a in saved) ...[
                  Material(
                    color: card,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.of(context).pop(a),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: line)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.location_on_outlined, size: 20, color: ink),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              if (a.label.isNotEmpty)
                                Text(a.label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w600, color: muted)),
                              Text(a.text, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13.5, fontWeight: FontWeight.w500, color: ink, height: 1.35)),
                            ]),
                          ),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (!_adding)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _adding = true),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add a new address', style: TextStyle(fontFamily: appPoppinFont)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: blue,
                      minimumSize: const Size.fromHeight(46),
                      side: BorderSide(color: line),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                else
                  Form(
                    key: _formKey,
                    child: Column(children: [
                      if (saved.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text('NEW ADDRESS',
                              style: TextStyle(fontFamily: appPoppinFont, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: muted)),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _field(_line1, 'House / flat no. and street *', required: 'Enter the house number and street.', max: 200),
                      _field(_line2, 'Area / locality', max: 200),
                      _field(_landmark, 'Landmark', max: 150),
                      Row(children: [
                        Expanded(child: _field(_city, 'City *', required: 'Enter the city.', max: 100)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _field(
                            _pincode,
                            'Pincode *',
                            max: 6,
                            keyboard: TextInputType.number,
                            formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                            validator: (v) => RegExp(r'^\d{6}$').hasMatch((v ?? '').trim()) ? null : 'Enter 6 digits.',
                          ),
                        ),
                      ]),
                      _field(_state, 'State', max: 100),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_error!, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 12, color: Colors.red)),
                        ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _useTyped,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Use this address', style: TextStyle(fontFamily: appPoppinFont, fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ]),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? required,
    int? max,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: formatters ?? (max == null ? null : [LengthLimitingTextInputFormatter(max)]),
          textCapitalization: keyboard == null ? TextCapitalization.words : TextCapitalization.none,
          style: const TextStyle(fontFamily: appPoppinFont, fontSize: 14),
          validator: validator ?? (required == null ? null : (v) => (v ?? '').trim().isEmpty ? required : null),
          decoration: InputDecoration(
            labelText: label,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
}
