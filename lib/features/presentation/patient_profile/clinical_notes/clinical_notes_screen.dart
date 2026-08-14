import 'dart:developer' as developer;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:yiraclinics/core/shimmer_widgets/base_shimmer.dart';
import 'package:intl/intl.dart';
import 'package:yiraclinics/core/api/api_client.dart';
import 'package:yiraclinics/core/colors/colors.dart';
import 'package:yiraclinics/core/common_size_helpers/common_size_helpers.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/urls/urls.dart';
import '../../../../core/common_widgets/custom_border_button.dart';
import '../../../../core/common_widgets/custom_button.dart';

class ClinicalNotesScreen extends StatefulWidget {
  final String? patientId;
  final String? appointmentId;
  final String? hospitalId;
  final String? orgId;

  const ClinicalNotesScreen({
    super.key,
    this.patientId,
    this.appointmentId,
    this.hospitalId,
    this.orgId,
  });

  @override
  State<ClinicalNotesScreen> createState() => _ClinicalNotesScreenState();
}

class _ClinicalNotesScreenState extends State<ClinicalNotesScreen> {
  late final TextEditingController _notesController;
  final ApiClient _apiClient = ApiClient();

  List<dynamic> _notesList = [];
  bool _isLoading = false;
  bool _isSaving = false;
  int? _editingNoteId;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _fetchClinicalNotes();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _fetchClinicalNotes() async {
    final pid = widget.patientId ?? '3456';
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      final queryParams = <String, dynamic>{};
      if (widget.appointmentId != null && widget.appointmentId!.trim().isNotEmpty) {
        queryParams['appointmentId'] = widget.appointmentId!.trim();
      }
      if (widget.hospitalId != null && widget.hospitalId!.trim().isNotEmpty) {
        queryParams['hospitalId'] = widget.hospitalId!.trim();
      }
      if (widget.orgId != null && widget.orgId!.trim().isNotEmpty) {
        queryParams['orgId'] = widget.orgId!.trim();
      }

      final response = await _apiClient.account(showSuccessSnack: false).get(
        '${URLs.clinicalNotesUrl}/patient/$pid',
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
            _notesList = data;
          });
        }
      }
    } catch (e, stack) {
      developer.log("Error fetching clinical notes", error: e, stackTrace: stack, name: "ClinicalNotesScreen");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveOrUpdateNote() async {
    final noteText = _notesController.text.trim();
    if (noteText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter clinical notes before saving")),
      );
      return;
    }

    setState(() => _isSaving = true);
    final pid = widget.patientId ?? '3456';

    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      if (_editingNoteId != null) {
        // Update existing note
        await _apiClient.account(showSuccessSnack: true).put(
          '${URLs.clinicalNotesUrl}/$_editingNoteId',
          data: {
            'notes': noteText,
            'updatedBy': currentUser?.data?.firstName ?? 'Doctor',
          },
          options: Options(
            headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
          ),
        );
      } else {
        // Add new note
        await _apiClient.account(showSuccessSnack: true).post(
          URLs.clinicalNotesUrl,
          data: {
            'patientId': pid,
            'appointmentId': widget.appointmentId,
            'hospitalId': widget.hospitalId,
            'organizationId': widget.orgId,
            'notes': noteText,
            'createdBy': currentUser?.data?.firstName ?? 'Doctor',
          },
          options: Options(
            headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
          ),
        );
      }

      _notesController.clear();
      _editingNoteId = null;
      await _fetchClinicalNotes();
    } catch (e, stack) {
      developer.log("Error saving clinical note", error: e, stackTrace: stack, name: "ClinicalNotesScreen");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteNote(int id) async {
    try {
      final currentUser = GlobalSession.instance.userNotifier.value;
      final String token = currentUser?.data?.accessToken ?? '';

      await _apiClient.account(showSuccessSnack: true).delete(
        '${URLs.clinicalNotesUrl}/$id',
        options: Options(
          headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
        ),
      );

      await _fetchClinicalNotes();
    } catch (e, stack) {
      developer.log("Error deleting clinical note", error: e, stackTrace: stack, name: "ClinicalNotesScreen");
    }
  }

  void _startEditing(dynamic noteItem) {
    _showNoteOverlay(context, noteItem);
  }

  void _showNoteOverlay(BuildContext context, [dynamic noteItem]) {
    if (noteItem != null) {
      _editingNoteId = noteItem['Id'] ?? noteItem['id'];
      _notesController.text = noteItem['Notes'] ?? noteItem['notes'] ?? '';
    } else {
      _editingNoteId = null;
      _notesController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? darkModeCardColor : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _editingNoteId != null ? 'Edit Clinical Note' : 'Add New Clinical Note',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(modalContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  maxLines: 5,
                  style: const TextStyle(
                    fontFamily: appPoppinFont,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter clinical observations, examination notes, recommendations...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade400,
                      fontFamily: appPoppinFont,
                    ),
                    filled: true,
                    fillColor: isDark ? darkModeCardColor.withOpacity(0.8) : Colors.grey.shade50,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fieldBorderRadius),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(fieldBorderRadius),
                      borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 100,
                      child: CommonBorderButton(
                        isPatientDetail: true,
                        height: 38,
                        text: 'Clear',
                        onPressed: () {
                          _notesController.clear();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatefulBuilder(
                      builder: (context, setModalState) {
                        return SizedBox(
                          width: 120,
                          child: CustomElevatedButton(
                            text: _isSaving ? "Saving..." : (_editingNoteId != null ? "Update" : "Save Note"),
                            onPressed: _isSaving
                                ? () {}
                                : () async {
                                    setModalState(() => _isSaving = true);
                                    await _saveOrUpdateNote();
                                    setModalState(() => _isSaving = false);
                                    if (modalContext.mounted) {
                                      Navigator.pop(modalContext);
                                    }
                                  },
                            width: double.infinity,
                            height: 38,
                            borderRadius: 8,
                          ),
                        );
                      }
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 650;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          _showNoteOverlay(context);
        },
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: _fetchClinicalNotes,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
              if (_isLoading)
                const SliverFillRemaining(
                  child: ClinicalNotesShimmer(itemCount: 3),
                )
              else if (_notesList.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWideScreen ? 24.0 : screenHorizontalSpacePadding,
                    ),
                    child: _buildEmptyStateView(context, isWideScreen),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = _notesList[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          right: isWideScreen ? 24.0 : screenHorizontalSpacePadding,
                          left: isWideScreen ? 24.0 : screenHorizontalSpacePadding,
                          bottom: 16,
                        ),
                        child: _buildHistoricalNoteCard(context, item, isWideScreen),
                      );
                    },
                    childCount: _notesList.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          ),
        ),
    );
  }

  Widget _buildHistoricalNoteCard(BuildContext context, dynamic noteItem, bool isWideScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int noteId = noteItem['Id'] ?? noteItem['id'] ?? 0;
    final String notesText = noteItem['Notes'] ?? noteItem['notes'] ?? '';
    final String createdBy = noteItem['CreatedBy'] ?? noteItem['createdBy'] ?? 'Doctor';
    final String createdAtRaw = noteItem['CreatedAt'] ?? noteItem['createdAt'] ?? '';

    String formattedDate = 'Recent Visit';
    if (createdAtRaw.isNotEmpty) {
      try {
        final parsed = DateTime.parse(createdAtRaw);
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
      } catch (_) {
        formattedDate = createdAtRaw;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? darkModeCardColor : Colors.white,
        borderRadius: BorderRadius.circular(fieldBorderRadius),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.medical_services_outlined,
                  size: 14,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate.toUpperCase(),
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade600),
                onPressed: () => _startEditing(noteItem),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 14),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                onPressed: () => _deleteNote(noteId),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            notesText,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: isWideScreen ? 14 : displayWidth(context) * 0.035,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'By Dr. $createdBy',
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 11,
              color: isDark ? Colors.white38 : Colors.black38,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateView(BuildContext context, bool isWideScreen) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 24.0),
        child: Column(
          children: [
            Icon(
              Icons.note_alt_outlined,
              size: isWideScreen ? 56 : 44,
              color: isDark ? Colors.white24 : Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Historical Clinical Notes Found',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: isWideScreen ? 16 : 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter notes above to record doctor clinical observations.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}