import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import 'add_suggestion_sheet.dart';

class DoctorSuggestionsScreen extends StatefulWidget {
  final String? patientId;
  final String? hospitalId;
  final String? orgId;
  final String? patientName;
  final bool showFab;

  const DoctorSuggestionsScreen({
    super.key,
    this.patientId,
    this.hospitalId,
    this.orgId,
    this.patientName,
    this.showFab = true,
  });

  @override
  State<DoctorSuggestionsScreen> createState() =>
      _DoctorSuggestionsScreenState();
}

class _DoctorSuggestionsScreenState extends State<DoctorSuggestionsScreen> {
  final ApiClient _apiClient = ApiClient();
  List<dynamic> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchSuggestions();
  }

  Future<void> _fetchSuggestions() async {
    final pid = widget.patientId ?? '3456';
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      final queryParams = <String, dynamic>{};
      if (widget.hospitalId != null && widget.hospitalId!.trim().isNotEmpty) {
        queryParams['hospitalId'] = widget.hospitalId!.trim();
      }
      if (widget.orgId != null && widget.orgId!.trim().isNotEmpty) {
        queryParams['orgId'] = widget.orgId!.trim();
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
          setState(() {
            _suggestions = data;
          });
        }
      }
    } catch (e, stack) {
      developer.log("Error fetching doctor suggestions",
          error: e, stackTrace: stack, name: "DoctorSuggestionsScreen");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteSuggestion(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Suggestion",
          style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to delete this suggestion? This action cannot be undone.",
          style: TextStyle(fontFamily: appPoppinFont, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel", style: TextStyle(fontFamily: appPoppinFont)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete", style: TextStyle(fontFamily: appPoppinFont)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      final response = await _apiClient.account(showSuccessSnack: false).delete(
        '${URLs.doctorSuggestionsUrl}/$id',
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Suggestion deleted successfully"),
              backgroundColor: Colors.black87,
            ),
          );
          _fetchSuggestions();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to delete: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openAddSuggestion() async {
    final added = await AddDoctorSuggestionSheet.show(
      context,
      patientId: widget.patientId ?? '3456',
      orgId: widget.orgId,
      hospitalId: widget.hospitalId,
      patientName: widget.patientName,
    );

    if (added == true) {
      _fetchSuggestions();
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dt);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isTab = isTablet(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: !widget.showFab
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddSuggestion,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                "Add Suggestion",
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
      body: RefreshIndicator(
        onRefresh: _fetchSuggestions,
        child: _isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: BaseShimmer(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              )
            : _suggestions.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.lightbulb_outline_rounded,
                              size: 48,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            "No Doctor Suggestions Yet",
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: isTab ? 18 : 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Give health tips, diet advice, or lifestyle recommendations directly to this patient.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12.5,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _openAddSuggestion,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text(
                              "Add First Suggestion",
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: _suggestions.length,
                    itemBuilder: (context, index) {
                      final item = _suggestions[index];
                      final int id = item['Id'] ?? 0;
                      final String title = item['Title'] ?? 'Suggestion';
                      final String description = item['Description'] ?? '';
                      final String createdAt = _formatDate(item['CreatedAt']);
                      final String? filePath = item['FilePath'];
                      final String? fileName = item['FileName'];

                      // Doctor Info
                      final doctor = item['Doctor'];
                      String doctorName = 'Doctor';
                      if (doctor != null) {
                        doctorName =
                            "Dr. ${(doctor['FirstName'] ?? '')} ${(doctor['LastName'] ?? '')}"
                                .trim();
                        if (doctorName == 'Dr.') doctorName = 'Doctor';
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.25)
                                  : const Color(0xFF64748B).withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: isTab ? 16 : 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        "By $doctorName • $createdAt",
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11,
                                          color: isDark
                                              ? Colors.white60
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (id > 0)
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: isDark
                                          ? Colors.white38
                                          : const Color(0xFF94A3B8),
                                    ),
                                    onPressed: () => _deleteSuggestion(id),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: "Delete suggestion",
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Description
                            Text(
                              description,
                              style: TextStyle(
                                fontFamily: appPoppinFont,
                                fontSize: 13,
                                height: 1.45,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : const Color(0xFF334155),
                              ),
                            ),

                            // Attachment if present
                            if (filePath != null && filePath.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () => _openFile(filePath),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB)
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.attach_file_rounded,
                                        size: 16,
                                        color: Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          fileName ?? "View Attached Document",
                                          style: const TextStyle(
                                            fontFamily: appPoppinFont,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2563EB),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.open_in_new_rounded,
                                        size: 14,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
