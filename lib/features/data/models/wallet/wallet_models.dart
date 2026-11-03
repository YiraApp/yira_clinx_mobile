import 'package:intl/intl.dart';

double _num(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
double? _numOrNull(dynamic v) => v == null || '$v'.isEmpty ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
String? _str(dynamic v) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty || s == 'null' ? null : s;
}

DateTime? _date(dynamic v) => DateTime.tryParse(v?.toString() ?? '');

/// "₹1,250" or "₹1,250.50", Indian digit grouping.
String formatRupees(double amount) {
  final whole = amount == amount.roundToDouble();
  return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: whole ? 0 : 2).format(amount);
}

/// "2026-10-20" for the API.
String walletDateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

const billCategories = ['Consultation', 'Pharmacy', 'Lab tests', 'Hospital stay', 'Procedure', 'Other'];
const paymentModes = ['Cash', 'UPI', 'Card', 'Net banking', 'Insurance', 'Other'];
const policyTypes = ['Health', 'Life', 'Accident', 'Critical illness', 'Government scheme', 'Other'];

/// Where a bill came from: raised by a Yira hospital, an online payment with
/// no bill, or added by the patient.
enum BillSource { hospital, payment, manual }

class BillItem {
  final String name;
  final double quantity;
  final double unitPrice;
  final double total;

  const BillItem({required this.name, required this.quantity, required this.unitPrice, required this.total});

  factory BillItem.fromJson(Map<String, dynamic> j) => BillItem(
        name: _str(j['name']) ?? 'Item',
        quantity: _num(j['quantity']) == 0 ? 1 : _num(j['quantity']),
        unitPrice: _num(j['unitPrice']),
        total: _num(j['total']),
      );
}

class BillEntry {
  final String id;
  final BillSource source;
  final String title;
  final String? provider;
  final String? doctor;
  final String category;
  final DateTime? date;
  final String? billNumber;
  final double total;
  final double paid;
  final double due;
  final String status;
  final String? paymentMode;
  final double subTotal;
  final double discount;
  final double tax;
  final List<BillItem> items;
  final String? notes;
  final String? fileUrl;
  final String? fileName;
  final bool editable;

  const BillEntry({
    required this.id,
    required this.source,
    required this.title,
    this.provider,
    this.doctor,
    required this.category,
    this.date,
    this.billNumber,
    required this.total,
    required this.paid,
    required this.due,
    required this.status,
    this.paymentMode,
    this.subTotal = 0,
    this.discount = 0,
    this.tax = 0,
    this.items = const [],
    this.notes,
    this.fileUrl,
    this.fileName,
    this.editable = false,
  });

  bool get isPaid => due <= 0;

  factory BillEntry.fromJson(Map<String, dynamic> j) => BillEntry(
        id: '${j['id']}',
        source: switch (j['source']) {
          'manual' => BillSource.manual,
          'payment' => BillSource.payment,
          _ => BillSource.hospital,
        },
        title: _str(j['title']) ?? 'Bill',
        provider: _str(j['provider']),
        doctor: _str(j['doctor']),
        category: _str(j['category']) ?? 'Other',
        date: _date(j['date']),
        billNumber: _str(j['billNumber']),
        total: _num(j['total']),
        paid: _num(j['paid']),
        due: _num(j['due']),
        status: _str(j['status']) ?? 'Paid',
        paymentMode: _str(j['paymentMode']),
        subTotal: _num(j['subTotal']),
        discount: _num(j['discount']),
        tax: _num(j['tax']),
        items: (j['items'] is List ? j['items'] as List : const [])
            .whereType<Map>()
            .map((e) => BillItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        notes: _str(j['notes']),
        fileUrl: _str(j['fileUrl']),
        fileName: _str(j['fileName']),
        editable: j['editable'] == true,
      );
}

class BillingSummary {
  final int count;
  final double totalBilled;
  final double totalPaid;
  final double totalDue;
  final double thisYear;
  final List<(String, double)> byCategory;

  const BillingSummary({
    this.count = 0,
    this.totalBilled = 0,
    this.totalPaid = 0,
    this.totalDue = 0,
    this.thisYear = 0,
    this.byCategory = const [],
  });

  factory BillingSummary.fromJson(Map<String, dynamic> j) => BillingSummary(
        count: _num(j['count']).toInt(),
        totalBilled: _num(j['totalBilled']),
        totalPaid: _num(j['totalPaid']),
        totalDue: _num(j['totalDue']),
        thisYear: _num(j['thisYear']),
        byCategory: (j['byCategory'] is List ? j['byCategory'] as List : const [])
            .whereType<Map>()
            .map((e) => ('${e['category']}', _num(e['total'])))
            .where((e) => e.$2 > 0)
            .toList(),
      );
}

class BillingData {
  final BillingSummary summary;
  final List<BillEntry> bills;

  const BillingData({required this.summary, required this.bills});

  factory BillingData.fromJson(Map<String, dynamic> j) => BillingData(
        summary: BillingSummary.fromJson(Map<String, dynamic>.from(j['summary'] as Map? ?? const {})),
        bills: (j['bills'] is List ? j['bills'] as List : const [])
            .whereType<Map>()
            .map((e) => BillEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

/// What a policy's renewal date means today.
enum PolicyState { active, renewSoon, expired, noDate }

class PolicyEntry {
  final String id;
  final bool fromHospital;
  final String policyType;
  final String insurer;
  final String? policyName;
  final String policyNumber;
  final String? memberId;
  final double? sumInsured;
  final double? premium;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? tpaName;
  final String? helplineNumber;
  final String? coveredMembers;
  final String? notes;
  final String? fileUrl;
  final String? fileName;
  final String? addedBy;
  final bool editable;

  const PolicyEntry({
    required this.id,
    this.fromHospital = false,
    required this.policyType,
    required this.insurer,
    this.policyName,
    required this.policyNumber,
    this.memberId,
    this.sumInsured,
    this.premium,
    this.startDate,
    this.endDate,
    this.tpaName,
    this.helplineNumber,
    this.coveredMembers,
    this.notes,
    this.fileUrl,
    this.fileName,
    this.addedBy,
    this.editable = false,
  });

  /// Days until the renewal date (negative once it has passed).
  int? daysLeft([DateTime? today]) {
    if (endDate == null) return null;
    final now = today ?? DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return d1.difference(d0).inDays;
  }

  PolicyState state([DateTime? today]) {
    final left = daysLeft(today);
    if (left == null) return PolicyState.noDate;
    if (left < 0) return PolicyState.expired;
    if (left <= 30) return PolicyState.renewSoon;
    return PolicyState.active;
  }

  factory PolicyEntry.fromJson(Map<String, dynamic> j) => PolicyEntry(
        id: '${j['id']}',
        fromHospital: j['source'] == 'hospital',
        policyType: _str(j['policyType']) ?? 'Health',
        insurer: _str(j['insurer']) ?? 'Insurance',
        policyName: _str(j['policyName']),
        policyNumber: _str(j['policyNumber']) ?? '',
        memberId: _str(j['memberId']),
        sumInsured: _numOrNull(j['sumInsured']),
        premium: _numOrNull(j['premium']),
        startDate: _date(j['startDate']),
        endDate: _date(j['endDate']),
        tpaName: _str(j['tpaName']),
        helplineNumber: _str(j['helplineNumber']),
        coveredMembers: _str(j['coveredMembers']),
        notes: _str(j['notes']),
        fileUrl: _str(j['fileUrl']),
        fileName: _str(j['fileName']),
        addedBy: _str(j['addedBy']),
        editable: j['editable'] == true,
      );
}
