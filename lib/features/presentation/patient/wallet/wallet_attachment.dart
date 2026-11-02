import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/widgets/phosphor_icons.dart';
import 'wallet_widgets.dart';

/// Asks for a photo (camera or gallery) or a PDF. Returns the local path.
Future<String?> pickWalletAttachment(BuildContext context) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = WalletColors(isDark);
  final choice = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => WalletSheet(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (key, icon, label) in [
              ('camera', PhosphorIconsBold.camera, 'Take a photo'),
              ('gallery', PhosphorIconsBold.image, 'Choose from gallery'),
              ('pdf', PhosphorIconsBold.filePdf, 'Choose a PDF'),
            ])
              ListTile(
                leading: PhosphorIcon(icon, size: 20, color: c.ink),
                title: Text(label, style: TextStyle(fontFamily: appPoppinFont, fontSize: 14, color: c.ink)),
                onTap: () => Navigator.pop(ctx, key),
              ),
          ],
        ),
      ),
    ),
  );
  if (choice == null) return null;
  if (choice == 'pdf') {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    return result?.files.single.path;
  }
  final photo = await ImagePicker().pickImage(
    source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
    imageQuality: 80,
    maxWidth: 2200,
  );
  return photo?.path;
}

Future<void> openWalletFile(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't open the file.")));
  }
}

/// The attach / attached row used in the bill and policy forms.
class WalletAttachmentField extends StatelessWidget {
  final String? localPath;
  final String? existingName;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final String emptyLabel;

  const WalletAttachmentField({
    super.key,
    required this.localPath,
    required this.existingName,
    required this.onPick,
    required this.onClear,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = WalletColors(isDark);
    final primary = Theme.of(context).primaryColor;
    final name = localPath?.split('/').last ?? existingName;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: name == null ? primary.withValues(alpha: 0.4) : c.line),
        ),
        child: Row(
          children: [
            PhosphorIcon(name == null ? PhosphorIconsBold.paperclip : PhosphorIconsBold.fileText, size: 18, color: name == null ? primary : c.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name ?? emptyLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: appPoppinFont,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: name == null ? primary : c.ink,
                ),
              ),
            ),
            if (name != null)
              IconButton(
                tooltip: 'Remove file',
                visualDensity: VisualDensity.compact,
                onPressed: onClear,
                icon: PhosphorIcon(PhosphorIconsBold.x, size: 16, color: c.muted),
              ),
          ],
        ),
      ),
    );
  }
}
