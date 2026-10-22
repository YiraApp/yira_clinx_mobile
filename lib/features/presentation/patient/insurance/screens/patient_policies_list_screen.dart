import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yiraclinics/core/api/base_api_configuration.dart';
import 'package:yiraclinics/core/common_widgets/in_app_document_viewer.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/services/patient_insurance_service.dart';
import 'package:yiraclinics/features/data/models/insurance/patient_insurance_policy_model.dart';
import 'package:yiraclinics/features/presentation/patient/insurance/screens/patient_add_edit_policy_screen.dart';
import 'package:yiraclinics/features/presentation/patient/insurance/widgets/delete_policy_confirmation_dialog.dart';

class PatientPoliciesListScreen extends StatefulWidget {
  const PatientPoliciesListScreen({super.key});

  @override
  State<PatientPoliciesListScreen> createState() => _PatientPoliciesListScreenState();
}

class _PatientPoliciesListScreenState extends State<PatientPoliciesListScreen> {
  final Set<String> _expandedPolicyIds = {};

  @override
  void initState() {
    super.initState();
    _loadPolicies();
  }

  Future<void> _loadPolicies() async {
    await PatientInsuranceService.instance.getPolicies();
  }

  void _onAddPolicy() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientAddEditPolicyScreen(),
      ),
    );
    if (result == true) {
      _loadPolicies();
    }
  }

  void _onEditPolicy(PatientInsurancePolicyModel policy) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientAddEditPolicyScreen(policy: policy),
      ),
    );
    if (result == true) {
      _loadPolicies();
    }
  }

  void _onDeletePolicy(PatientInsurancePolicyModel policy) async {
    bool deleteSuccess = false;
    final confirmed = await DeletePolicyConfirmationDialog.show(
      context,
      onConfirmAsync: () async {
        deleteSuccess = await PatientInsuranceService.instance.deletePolicy(policy.id);
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: deleteSuccess ? const Color(0xFF10B981) : Colors.red,
          content: Text(
            deleteSuccess ? 'Policy deleted successfully.' : 'Failed to delete policy.',
            style: const TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
  }

  String _resolveDocumentUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    String normalized = url.trim();
    final rawBaseUrl = EnvironmentService.config.accountBaseUrl.trim();
    final baseUrl = rawBaseUrl.startsWith('http') ? rawBaseUrl : 'https://$rawBaseUrl';

    if (!normalized.startsWith('http://') && !normalized.startsWith('https://') && !normalized.contains('://')) {
      if (normalized.startsWith('/')) {
        normalized = '$baseUrl$normalized';
      } else {
        normalized = '$baseUrl/$normalized';
      }
    }
    if (baseUrl.startsWith('http') &&
        (normalized.contains('localhost:5000') ||
         normalized.contains('127.0.0.1:5000') ||
         RegExp(r'192\.168\.\d+\.\d+(:\d+)?').hasMatch(normalized))) {
      normalized = normalized.replaceAll(RegExp(r'https?://[^/]+'), baseUrl);
    }
    return normalized;
  }

  void _openDocument(PatientInsurancePolicyModel policy) {
    final filePath = policy.localFilePath;
    final fileUrl = policy.documentUrl;
    final resolvedUrl = _resolveDocumentUrl(fileUrl);

    final hasValidLocalFile = filePath != null &&
        filePath.isNotEmpty &&
        File(filePath).existsSync();

    if (!hasValidLocalFile && resolvedUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document file attached to this policy.')),
      );
      return;
    }

    final fileName = hasValidLocalFile
        ? filePath.split(RegExp(r'[/\\]')).last
        : resolvedUrl.split('/').last.split('?').first;

    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final fileType = isPdf ? 'PDF' : 'IMAGE';

    InAppDocumentViewer.show(
      context,
      title: policy.policyName.isNotEmpty ? policy.policyName : 'Policy Document',
      category: 'Insurance Policy',
      filePath: hasValidLocalFile ? filePath : null,
      fileUrl: hasValidLocalFile ? null : resolvedUrl,
      fileType: fileType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryBlue = const Color(0xFF2563EB);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.shield_outlined,
                color: Color(0xFF2563EB),
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Policies',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontWeight: FontWeight.w700,
                fontSize: 16.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: PatientInsuranceService.instance.isLoadingNotifier,
        builder: (context, isLoading, _) {
          return ValueListenableBuilder<List<PatientInsurancePolicyModel>>(
            valueListenable: PatientInsuranceService.instance.policiesNotifier,
            builder: (context, policies, _) {
              if (isLoading && policies.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                );
              }

              return RefreshIndicator(
                color: primaryBlue,
                onRefresh: _loadPolicies,
                child: policies.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: policies.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final policy = policies[index];
                          final idStr = policy.id.toString();
                          final isExpanded = _expandedPolicyIds.contains(idStr);

                          return _buildPolicyCard(
                            policy: policy,
                            isExpanded: isExpanded,
                            isDark: isDark,
                            onToggleExpand: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedPolicyIds.remove(idStr);
                                } else {
                                  _expandedPolicyIds.add(idStr);
                                }
                              });
                            },
                          );
                        },
                      ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _onAddPolicy,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Add New Policy',
                    style: TextStyle(
                      fontFamily: appPoppinFont,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
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

  Widget _buildPolicyCard({
    required PatientInsurancePolicyModel policy,
    required bool isExpanded,
    required bool isDark,
    required VoidCallback onToggleExpand,
  }) {
    final provider = policy.insuranceProvider.isNotEmpty ? policy.insuranceProvider : 'Insurance Provider';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Umbrella Icon + Provider Title + Edit/Delete Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              children: [
                // Umbrella / Shield Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.beach_access_rounded, // Umbrella icon matching reference app
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Provider Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider,
                        style: TextStyle(
                          fontFamily: appPoppinFont,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (policy.policyName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          policy.policyName,
                          style: TextStyle(
                            fontFamily: appPoppinFont,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF2563EB),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Edit Button
                IconButton(
                  tooltip: 'Edit Policy',
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF2563EB)),
                  onPressed: () => _onEditPolicy(policy),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),

                // Delete Button
                IconButton(
                  tooltip: 'Delete Policy',
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                  onPressed: () => _onDeletePolicy(policy),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),

          // Body Meta Fields (Full Width & Clean)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                _buildMetaRow('Policy Holder', ': ${policy.policyHolder.isNotEmpty ? policy.policyHolder : '-'}', isDark),
                const SizedBox(height: 6),
                _buildMetaRow('Policy Name', ': ${policy.policyName.isNotEmpty ? policy.policyName : '-'}', isDark),
                const SizedBox(height: 6),
                _buildMetaRow('Policy No', ': ${policy.policyNumber.isNotEmpty ? policy.policyNumber : '-'}', isDark),
                const SizedBox(height: 6),
                _buildMetaRow('Validity', ': ${policy.validityText}', isDark),
              ],
            ),
          ),

          // Expandable section for document preview (revealed when arrow is clicked)
          if (isExpanded) ...[
            Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: ((policy.localFilePath != null && policy.localFilePath!.isNotEmpty) ||
                      (policy.documentUrl != null && policy.documentUrl!.isNotEmpty))
                  ? Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Small image thumbnail - tap to view full screen
                          _buildDocumentThumbnail(policy: policy, isDark: isDark),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _openDocument(policy),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (policy.localFilePath != null && policy.localFilePath!.isNotEmpty)
                                        ? policy.localFilePath!.split(RegExp(r'[/\\]')).last
                                        : (policy.documentUrl != null && policy.documentUrl!.isNotEmpty)
                                            ? policy.documentUrl!.split('/').last
                                            : 'Insurance Document',
                                    style: TextStyle(
                                      fontFamily: appPoppinFont,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      const Icon(Icons.touch_app_outlined, size: 13, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Tap to view full screen',
                                        style: TextStyle(
                                          fontFamily: appPoppinFont,
                                          fontSize: 11,
                                          color: const Color(0xFF2563EB),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.description_outlined,
                              size: 18, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)),
                          const SizedBox(width: 8),
                          Text(
                            'No document attached',
                            style: TextStyle(
                              fontFamily: appPoppinFont,
                              fontSize: 12,
                              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],

          // Expand/Collapse Chevron Button
          InkWell(
            onTap: onToggleExpand,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              alignment: Alignment.center,
              child: Icon(
                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentThumbnail({
    required PatientInsurancePolicyModel policy,
    required bool isDark,
  }) {
    final filePath = policy.localFilePath;
    final fileUrl = policy.documentUrl;
    final hasLocal = filePath != null && filePath.isNotEmpty && File(filePath).existsSync();
    final resolvedUrl = _resolveDocumentUrl(fileUrl);
    final hasRemote = resolvedUrl.isNotEmpty;

    if (!hasLocal && !hasRemote) return const SizedBox.shrink();

    final fileName = hasLocal
        ? filePath.split(RegExp(r'[/\\]')).last
        : resolvedUrl.split('/').last.split('?').first;
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    return InkWell(
      onTap: () => _openDocument(policy),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF2563EB).withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isPdf)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 28),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'PDF',
                      style: TextStyle(
                        fontFamily: appPoppinFont,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              )
            else if (hasLocal)
              Padding(
                padding: const EdgeInsets.all(3),
                child: Image.file(
                  File(filePath),
                  width: 68,
                  height: 68,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(3),
                child: CachedNetworkImage(
                  imageUrl: resolvedUrl,
                  width: 68,
                  height: 68,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  placeholder: (ctx, url) => const Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                    ),
                  ),
                  errorWidget: (ctx, url, err) => const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: appPoppinFont,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.18 : 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.beach_access_rounded,
                size: 40,
                color: Color(0xFF2563EB),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Insurance Policies Added',
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Store and manage your global medical and health insurance policies in one secure place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: appPoppinFont,
                fontSize: 13,
                height: 1.4,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _onAddPolicy,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Your First Policy'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFF2563EB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
