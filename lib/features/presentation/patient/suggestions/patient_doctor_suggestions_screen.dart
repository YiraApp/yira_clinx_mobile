import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'package:yiraclinics/features/presentation/patient/appointments/patient_add_new_appointment_screen.dart';

class PatientDoctorSuggestionsScreen extends StatefulWidget {
  final String? patientId;
  final String? hospitalId;
  final String? orgId;

  const PatientDoctorSuggestionsScreen({
    super.key,
    this.patientId,
    this.hospitalId,
    this.orgId,
  });

  @override
  State<PatientDoctorSuggestionsScreen> createState() =>
      _PatientDoctorSuggestionsScreenState();
}

class _PatientDoctorSuggestionsScreenState
    extends State<PatientDoctorSuggestionsScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allSuggestions = [];
  List<dynamic> _filteredSuggestions = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _searchQuery = '';

  static const Color _primaryBlue = Color(0xFF2563EB);

  final List<String> _categories = [
    'All',
    'Lifestyle',
    'Diet & Nutrition',
    'Medication',
    'Exercise',
    'Follow-up',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuggestions() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final currentUser = GlobalSession.instance.userNotifier.value;
    final pid = widget.patientId ?? currentUser?.data?.id ?? '';

    if (pid.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final String token = currentUser?.data?.accessToken ?? '';
      final queryParams = <String, dynamic>{};
      final effectiveHospitalId = widget.hospitalId ??
          currentUser?.data?.latestHospitalId?.toString();
      final effectiveOrgId = widget.orgId ??
          currentUser?.data?.latestOrgId?.toString();

      if (effectiveHospitalId != null &&
          effectiveHospitalId.trim().isNotEmpty) {
        queryParams['hospitalId'] = effectiveHospitalId.trim();
      }
      if (effectiveOrgId != null && effectiveOrgId.trim().isNotEmpty) {
        queryParams['orgId'] = effectiveOrgId.trim();
      }

      final response = await _apiClient.account(showSuccessSnack: false).get(
        '${URLs.doctorSuggestionsUrl}/patient/$pid',
        queryParameters: queryParams,
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (!mounted) return;
      if (response.data != null && response.data is Map<String, dynamic>) {
        final data = response.data['data'];
        if (data is List) {
          _allSuggestions = List<dynamic>.from(data);
          _applyFilters();
        }
      }
    } catch (_) {
      // Graceful fallback for offline / errors
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    List<dynamic> result = List.from(_allSuggestions);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      result = result.where((item) {
        final title = (item['Title'] ?? '').toString().toLowerCase();
        final desc = (item['Description'] ?? '').toString().toLowerCase();
        final doc = item['Doctor'];
        String docName = '';
        if (doc is Map) {
          docName =
              "${doc['FirstName'] ?? ''} ${doc['LastName'] ?? ''}".toLowerCase();
        }
        return title.contains(q) || desc.contains(q) || docName.contains(q);
      }).toList();
    }

    if (_selectedCategory != 'All') {
      result = result.where((item) {
        final cat = _getCategoryForItem(item);
        return cat.toLowerCase() == _selectedCategory.toLowerCase();
      }).toList();
    }

    setState(() {
      _filteredSuggestions = result;
    });
  }

  String _getCategoryForItem(dynamic item) {
    final title = (item['Title'] ?? '').toString().toLowerCase();
    final desc = (item['Description'] ?? '').toString().toLowerCase();
    final full = '$title $desc';

    if (full.contains('diet') ||
        full.contains('food') ||
        full.contains('nutrition') ||
        full.contains('meal') ||
        full.contains('sugar') ||
        full.contains('salt') ||
        full.contains('eat')) {
      return 'Diet & Nutrition';
    }
    if (full.contains('med') ||
        full.contains('pill') ||
        full.contains('tablet') ||
        full.contains('dose') ||
        full.contains('syrup') ||
        full.contains('capsule') ||
        full.contains('injection')) {
      return 'Medication';
    }
    if (full.contains('walk') ||
        full.contains('exercise') ||
        full.contains('gym') ||
        full.contains('run') ||
        full.contains('yoga') ||
        full.contains('stretch') ||
        full.contains('workout')) {
      return 'Exercise';
    }
    if (full.contains('lifestyle') ||
        full.contains('sleep') ||
        full.contains('water') ||
        full.contains('hydrate') ||
        full.contains('stress') ||
        full.contains('routine') ||
        full.contains('habit')) {
      return 'Lifestyle';
    }
    if (full.contains('follow') ||
        full.contains('review') ||
        full.contains('visit') ||
        full.contains('checkup') ||
        full.contains('test') ||
        full.contains('next appointment')) {
      return 'Follow-up';
    }
    return 'General';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Diet & Nutrition':
        return const Color(0xFF10B981); // Emerald
      case 'Medication':
        return const Color(0xFF8B5CF6); // Violet
      case 'Exercise':
        return const Color(0xFFF97316); // Orange
      case 'Lifestyle':
        return const Color(0xFF06B6D4); // Cyan
      case 'Follow-up':
        return const Color(0xFFE11D48); // Rose
      default:
        return _primaryBlue;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Diet & Nutrition':
        return Icons.restaurant_rounded;
      case 'Medication':
        return Icons.medication_rounded;
      case 'Exercise':
        return Icons.directions_run_rounded;
      case 'Lifestyle':
        return Icons.spa_rounded;
      case 'Follow-up':
        return Icons.event_repeat_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(dt);

      if (difference.inDays == 0) {
        return "Today, ${DateFormat('hh:mm a').format(dt)}";
      } else if (difference.inDays == 1) {
        return "Yesterday, ${DateFormat('hh:mm a').format(dt)}";
      } else if (difference.inDays < 7) {
        return "${difference.inDays} days ago";
      } else {
        return DateFormat('MMM dd, yyyy').format(dt);
      }
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open attachment")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error opening file: $e")),
        );
      }
    }
  }

  void _showSuggestionDetails(Map<String, dynamic> item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTab = isTablet(context);

    final String title = item['Title'] ?? 'Doctor Suggestion';
    final String description = item['Description'] ?? '';
    final String createdAt = _formatDate(item['CreatedAt']);
    final String? filePath = item['FilePath'];
    final String? fileName = item['FileName'];
    final category = _getCategoryForItem(item);
    final categoryColor = _getCategoryColor(category);

    final doctor = item['Doctor'];
    String doctorName = 'Attending Doctor';
    String? doctorSpecialty;
    String? doctorId;
    if (doctor != null && doctor is Map) {
      doctorId = doctor['Id']?.toString();
      final fn = (doctor['FirstName'] ?? '').toString().trim();
      final ln = (doctor['LastName'] ?? '').toString().trim();
      if (fn.isNotEmpty || ln.isNotEmpty) {
        doctorName = "Dr. $fn $ln".trim();
      }
      doctorSpecialty = doctor['Specialization']?.toString();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _getCategoryIcon(category),
                      color: categoryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: categoryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category.toUpperCase(),
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: categoryColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: isTab ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "$doctorName • $createdAt",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            color: isDark
                                ? Colors.white60
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Doctor's Advice & Care Plan",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  description,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13.5,
                    height: 1.6,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              if (filePath != null && filePath.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  "Attached Medical Document",
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _openFile(filePath),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _primaryBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_file_rounded,
                          color: _primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            fileName ?? "View Attached Document",
                            style: const TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _primaryBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(
                          Icons.open_in_new_rounded,
                          color: _primaryBlue,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFCBD5E1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 18),
                      label: const Text(
                        "Got It",
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (doctorId != null && doctorId.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientAddNewAppointmentScreen(
                                initialDoctorId: doctorId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_month_rounded,
                            size: 18),
                        label: const Text(
                          "Consult Doctor",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Doctor Suggestions",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 19 : 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              "Personalized advice & lifestyle guidance",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isTab ? 13 : 11.5,
                fontWeight: FontWeight.normal,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          if (_allSuggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _primaryBlue.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _primaryBlue.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    "${_filteredSuggestions.length} items",
                    style: const TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: _primaryBlue,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchSuggestions,
        color: _primaryBlue,
        child: Column(
          children: [
            // Search Bar & Filter Section
            Container(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Search Field
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        _searchQuery = val;
                        _applyFilters();
                      },
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: InputDecoration(
                        hintText: "Search suggestions or doctor...",
                        hintStyle: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 13,
                          color:
                              isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    size: 18, color: Color(0xFF64748B)),
                                onPressed: () {
                                  _searchController.clear();
                                  _searchQuery = '';
                                  _applyFilters();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category Filter Chips
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = _categories[index];
                        final isSelected = _selectedCategory == cat;
                        final color = isSelected
                            ? _primaryBlue
                            : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0));

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategory = cat;
                            });
                            _applyFilters();
                          },
                          borderRadius: BorderRadius.circular(18),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _primaryBlue
                                  : (isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: color,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (cat != 'All') ...[
                                  Icon(
                                    _getCategoryIcon(cat),
                                    size: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : const Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  cat,
                                  style: TextStyle(
                                    fontFamily: appPoppinFont,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? Colors.white70
                                            : const Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Suggestions List or States
            Expanded(
              child: _isLoading
                  ? _buildShimmerLoading(isDark)
                  : _filteredSuggestions.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          itemCount: _filteredSuggestions.length,
                          itemBuilder: (context, index) {
                            final item = _filteredSuggestions[index];
                            return _buildSuggestionCard(
                                item, isDark, isTab, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(
      dynamic item, bool isDark, bool isTab, int index) {
    final String title = item['Title'] ?? 'Suggestion';
    final String description = item['Description'] ?? '';
    final String createdAt = _formatDate(item['CreatedAt']);
    final String? filePath = item['FilePath'];
    final String? fileName = item['FileName'];
    final category = _getCategoryForItem(item);
    final categoryColor = _getCategoryColor(category);

    final doctor = item['Doctor'];
    String doctorName = 'Doctor';
    String? doctorSpecialty;
    String? doctorId;
    if (doctor != null && doctor is Map) {
      doctorId = doctor['Id']?.toString();
      final fn = (doctor['FirstName'] ?? '').toString().trim();
      final ln = (doctor['LastName'] ?? '').toString().trim();
      if (fn.isNotEmpty || ln.isNotEmpty) {
        doctorName = "Dr. $fn $ln".trim();
      }
      doctorSpecialty = doctor['Specialization']?.toString();
    }

    final doctorInitials = doctorName.replaceAll('Dr. ', '').trim();
    final initial = doctorInitials.isNotEmpty ? doctorInitials[0] : 'D';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showSuggestionDetails(Map<String, dynamic>.from(item)),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Doctor & Category Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Doctor Avatar
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            categoryColor.withValues(alpha: 0.8),
                            categoryColor,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          initial.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: appPoppinFont,
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Doctor Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doctorName,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 15 : 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          if (doctorSpecialty != null &&
                              doctorSpecialty.isNotEmpty)
                            Text(
                              doctorSpecialty,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Category Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(category),
                            size: 13,
                            color: categoryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            category,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: categoryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: isTab ? 16 : 14.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 12.5,
                    height: 1.5,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.75)
                        : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 12),

                // Attachment Preview if present
                if (filePath != null && filePath.isNotEmpty) ...[
                  InkWell(
                    onTap: () => _openFile(filePath),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: _primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _primaryBlue.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.attachment_rounded,
                            size: 15,
                            color: _primaryBlue,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              fileName ?? "Attached Medical Report",
                              style: const TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _primaryBlue,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.open_in_new_rounded,
                            size: 13,
                            color: _primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Footer Row: Date & Action
                Divider(
                  height: 16,
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFF1F5F9),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 14,
                          color:
                              isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          createdAt,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 11.5,
                            color: isDark
                                ? Colors.white38
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          "View Details",
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: _primaryBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 46,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? "No Matching Suggestions"
                  : "No Doctor Suggestions Yet",
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != 'All'
                  ? "Try adjusting your search terms or category filter."
                  : "Personalized advice, health tips, and care plans shared by your doctors will appear here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                _searchController.clear();
                _searchQuery = '';
                _selectedCategory = 'All';
                _fetchSuggestions();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                "Refresh",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: BaseShimmer(
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
