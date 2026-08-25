import 'package:flutter/material.dart';
import '../../../../core/common_size_helpers/common_size_helpers.dart';
import '../../../../core/constants/constants.dart';

class DocumentUploadViaLinkScreen extends StatefulWidget {
  final String? token;

  const DocumentUploadViaLinkScreen({super.key, this.token});

  @override
  State<DocumentUploadViaLinkScreen> createState() => _DocumentUploadViaLinkScreenState();
}

class _DocumentUploadViaLinkScreenState extends State<DocumentUploadViaLinkScreen> {
  final _titleController = TextEditingController();
  String _selectedCategory = 'Lab Report';
  bool _isUploading = false;
  bool _uploadSuccess = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _handleUpload() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a document title.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isUploading = false;
      _uploadSuccess = true;
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
        title: const Text('Secure Document Upload', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold)),
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
              child: _uploadSuccess
                  ? Column(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
                        const SizedBox(height: 16),
                        const Text('Upload Successful!', style: TextStyle(fontFamily: appPoppinFont, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Your medical document has been securely attached to your appointment record.', textAlign: TextAlign.center, style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, color: Colors.grey)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Return to App', style: TextStyle(fontFamily: appPoppinFont, color: Colors.white)),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Secure Token Link Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_clock_rounded, color: Colors.amber[800], size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Secure Link Active (Token: ${widget.token ?? 'PAT-8842-SECURE'}) • Expires in 48 Hours',
                                  style: TextStyle(fontFamily: appPoppinFont, fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber[900]),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        Text('Document Title', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _titleController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Blood Test Report / MRI Scan',
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 14),

                        Text('Document Category', style: TextStyle(fontFamily: appPoppinFont, fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                          items: ['Lab Report', 'Imaging / X-Ray', 'Previous Prescription', 'Insurance Card']
                              .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontFamily: appPoppinFont, fontSize: 13))))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val!),
                        ),
                        const SizedBox(height: 20),

                        // Dropzone Area
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: primaryColor.withOpacity(0.3), style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.cloud_upload_rounded, color: primaryColor, size: 44),
                              const SizedBox(height: 8),
                              const Text('Select or drag files here (PDF, JPG, PNG up to 25MB)', textAlign: TextAlign.center, style: TextStyle(fontFamily: appPoppinFont, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                            onPressed: _isUploading ? null : _handleUpload,
                            child: _isUploading
                                ? const CircularProgressIndicator.adaptive(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                                : const Text('Upload Document via Link', style: TextStyle(fontFamily: appPoppinFont, fontWeight: FontWeight.bold, color: Colors.white)),
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
}
