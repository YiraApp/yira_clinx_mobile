import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yiraclinics/core/common_widgets/in_app_document_viewer.dart';
import 'package:yiraclinics/core/widgets/medical_loader.dart';
import 'package:yiraclinics/features/data/data_sources/diet/diet_api_error.dart';

/// Downloads a diet plan's PDF with [download] and opens it in the in-app viewer.
/// A loader covers the screen meanwhile; a failure shows a message instead.
Future<void> openDietPlanPdf(
  BuildContext context, {
  required int planId,
  required String planName,
  required Future<List<int>> Function() download,
  String? doctorName,
  String category = 'Diet Plan',
  String filePrefix = 'diet-plan',
  String errorMessage = "Couldn't open the diet plan PDF. Please try again.",
}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  var loaderOpen = true;
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: Center(
        child: Material(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF232323) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.fromLTRB(28, 24, 28, 20),
            child: MedicalLoader(message: 'Preparing your PDF…', size: 0.8),
          ),
        ),
      ),
    ),
  ).whenComplete(() => loaderOpen = false);

  try {
    final bytes = await download();
    if (bytes.isEmpty) throw Exception('The PDF came back empty.');
    final dir = await getTemporaryDirectory();
    final safeName = planName.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    final file = File('${dir.path}/$filePrefix-$planId${safeName.isEmpty ? '' : '-$safeName'}.pdf');
    await file.writeAsBytes(bytes, flush: true);
    if (loaderOpen) navigator.pop();
    if (!context.mounted) return;
    InAppDocumentViewer.show(
      context,
      title: planName.trim().isEmpty ? category : planName.trim(),
      category: category,
      filePath: file.path,
      fileType: 'PDF',
      doctorName: doctorName,
    );
  } catch (e) {
    if (loaderOpen) navigator.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(dietApiErrorMessage(e, errorMessage))));
  }
}
