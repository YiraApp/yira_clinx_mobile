import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yiraclinics/config/app_route/app_routes.dart';
import 'package:yiraclinics/core/constants/constants.dart';
import 'package:yiraclinics/core/local/global_session.dart';
import 'package:yiraclinics/core/widgets/entity_logo.dart';
import 'package:yiraclinics/core/widgets/phosphor_icons.dart';
import 'package:yiraclinics/features/data/data_sources/share/profile_share_remote_data_source.dart';

const Color _blue = Color(0xFF2563EB);
const Color _green = Color(0xFF059669);
const Color _amber = Color(0xFFD97706);
const Color _red = Color(0xFFDC2626);

Color _text(bool d) => d ? Colors.white : const Color(0xFF0F172A);
Color _muted(bool d) => d ? Colors.white60 : const Color(0xFF64748B);
Color _card(bool d) => d ? const Color(0xFF1E293B) : Colors.white;
Color _line(bool d) => d ? const Color(0xFF334155) : const Color(0xFFE6EAF0);
Color _page(bool d) => d ? const Color(0xFF0F172A) : const Color(0xFFF4F6FA);

TextStyle _ts(double size, FontWeight w, Color c, {double? height}) =>
    TextStyle(fontFamily: appPoppinFont, fontSize: size, fontWeight: w, color: c, height: height);

/// Share my profile: give a doctor on Yira access in their app, or make a
/// read-only web link for a doctor who is not on Yira.
class ShareProfileScreen extends StatefulWidget {
  /// For tests; the app uses the real API.
  final ProfileShareRemoteDataSource? dataSource;

  /// 0 = doctor on Yira, 1 = web link.
  final int initialOption;

  const ShareProfileScreen({super.key, this.dataSource, this.initialOption = 0});

  @override
  State<ShareProfileScreen> createState() => _ShareProfileScreenState();
}

class _ShareProfileScreenState extends State<ShareProfileScreen> {
  late final ProfileShareRemoteDataSource _api = widget.dataSource ?? ProfileShareRemoteDataSource();
  late int _option = widget.initialOption;

  bool _loadingDoctors = true;
  bool _loadingLinks = true;
  String? _doctorsError;
  String? _linksError;
  List<ShareableDoctor> _doctors = const [];
  List<ProfileShareLink> _links = const [];
  final Set<String> _busy = {};

  static final DateFormat _dateTime = DateFormat('d MMM, h:mm a');
  static final DateFormat _date = DateFormat('d MMM yyyy');

  String get _profileName {
    final d = GlobalSession.instance.userNotifier.value?.data;
    final name = '${d?.firstName ?? ''} ${d?.lastName ?? ''}'.trim();
    return name.isEmpty ? 'your' : "$name's";
  }

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _loadLinks();
  }

  Future<void> _loadDoctors() async {
    setState(() {
      _loadingDoctors = true;
      _doctorsError = null;
    });
    try {
      final doctors = await _api.getDoctors();
      if (mounted) setState(() => _doctors = doctors);
    } catch (e) {
      if (mounted) setState(() => _doctorsError = shareErrorMessage(e, "Couldn't load your doctors."));
    } finally {
      if (mounted) setState(() => _loadingDoctors = false);
    }
  }

  Future<void> _loadLinks() async {
    setState(() {
      _loadingLinks = true;
      _linksError = null;
    });
    try {
      final links = await _api.getLinks();
      if (mounted) setState(() => _links = links);
    } catch (e) {
      if (mounted) setState(() => _linksError = shareErrorMessage(e, "Couldn't load your links."));
    } finally {
      if (mounted) setState(() => _loadingLinks = false);
    }
  }

  void _toast(String message, {Color? color}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, style: _ts(13, FontWeight.w500, Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
  }

  // ─── Doctors on Yira ───────────────────────────────────────────────────

  Future<void> _giveAccess(ShareableDoctor doctor) async {
    final duration = await _pickDuration(
      title: 'Share with ${doctor.name}',
      message: 'They will see your full health history in their Yira app: visits, prescriptions, records and documents from every hospital.',
      options: const [('1_DAY', '1 day'), ('7_DAYS', '7 days'), ('1_MONTH', '1 month')],
      confirm: 'Share profile',
    );
    if (duration == null || !mounted) return;
    setState(() => _busy.add(doctor.id));
    try {
      await _api.grantDoctorAccess(doctorId: doctor.id, duration: duration, hospitalId: doctor.hospitalId);
      _toast('${doctor.name} can now see your records.', color: _green);
      await _loadDoctors();
    } catch (e) {
      _toast(shareErrorMessage(e, "Couldn't share your profile. Please try again."), color: _red);
    } finally {
      if (mounted) setState(() => _busy.remove(doctor.id));
    }
  }

  Future<void> _stopAccess(ShareableDoctor doctor) async {
    if (doctor.consentId == null) return;
    final ok = await _confirm(
      title: 'Stop sharing with ${doctor.name}?',
      message: 'They will only see records from their own hospital, as for any patient who visits.',
      confirm: 'Stop sharing',
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(doctor.id));
    try {
      await _api.stopDoctorAccess(doctor.consentId!);
      _toast('Stopped sharing with ${doctor.name}.');
      await _loadDoctors();
    } catch (e) {
      _toast(shareErrorMessage(e, "Couldn't stop sharing. Please try again."), color: _red);
    } finally {
      if (mounted) setState(() => _busy.remove(doctor.id));
    }
  }

  // ─── Web links ─────────────────────────────────────────────────────────

  Future<void> _createLink() async {
    final labelCtrl = TextEditingController();
    final duration = await _pickDuration(
      title: 'Create a web link',
      message: 'Anyone with the link can open $_profileName health records in a browser, without logging in, until it expires. Send it only to your doctor.',
      options: const [('1_DAY', '1 day'), ('7_DAYS', '7 days'), ('30_DAYS', '30 days')],
      confirm: 'Create link',
      labelController: labelCtrl,
    );
    // Not disposed here: the sheet may still be animating closed.
    final label = labelCtrl.text;
    if (duration == null || !mounted) return;
    setState(() => _busy.add('new-link'));
    ProfileShareLink? link;
    try {
      link = await _api.createLink(duration: duration, label: label);
      await _loadLinks();
    } catch (e) {
      _toast(shareErrorMessage(e, "Couldn't create the link. Please try again."), color: _red);
    } finally {
      if (mounted) setState(() => _busy.remove('new-link'));
    }
    // Shown after the button stops spinning, since the sheet stays open a while.
    if (mounted && link?.url != null) await _showLinkReady(link!);
  }

  Future<void> _revokeLink(ProfileShareLink link) async {
    final ok = await _confirm(
      title: 'Turn this link off?',
      message: 'Anyone who opens it will see that it has been turned off. You can make a new link at any time.',
      confirm: 'Turn off',
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add('link-${link.id}'));
    try {
      await _api.revokeLink(link.id);
      _toast('Link turned off.');
      await _loadLinks();
    } catch (e) {
      _toast(shareErrorMessage(e, "Couldn't turn the link off. Please try again."), color: _red);
    } finally {
      if (mounted) setState(() => _busy.remove('link-${link.id}'));
    }
  }

  Future<void> _showLinkReady(ProfileShareLink link) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final url = link.url!;
    final message = 'Here is a link to my health records on Yira Health. '
        'It works until ${link.expiresAt == null ? 'it is turned off' : _date.format(link.expiresAt!)}.\n$url';
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _Sheet(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PhosphorIcon(PhosphorIconsFill.checkCircle, color: _green, size: 26),
                const SizedBox(width: 10),
                Expanded(child: Text('Your link is ready', style: _ts(17, FontWeight.w700, _text(isDark)))),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Copy or share it now. For your safety this link is shown only once; you can always make a new one.',
              style: _ts(12.5, FontWeight.w400, _muted(isDark), height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _page(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _line(isDark)),
              ),
              child: SelectableText(url, style: _ts(12, FontWeight.w500, _text(isDark), height: 1.35)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      _toast('Link copied');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _blue,
                      minimumSize: const Size(0, 48),
                      side: BorderSide(color: _blue.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const PhosphorIcon(PhosphorIconsBold.copy, size: 18, color: _blue),
                    label: Text('Copy', style: _ts(14, FontWeight.w700, _blue)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => SharePlus.instance.share(ShareParams(text: message, subject: 'My health records')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const PhosphorIcon(PhosphorIconsBold.shareNetwork, size: 18, color: Colors.white),
                    label: Text('Share', style: _ts(14, FontWeight.w700, Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Sheets ────────────────────────────────────────────────────────────

  Future<String?> _pickDuration({
    required String title,
    required String message,
    required List<(String, String)> options,
    required String confirm,
    TextEditingController? labelController,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selected = options[1].$1;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: StatefulBuilder(
          builder: (ctx, setSheet) => _Sheet(
            isDark: isDark,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _ts(17, FontWeight.w700, _text(isDark))),
                const SizedBox(height: 6),
                Text(message, style: _ts(12.5, FontWeight.w400, _muted(isDark), height: 1.45)),
                if (labelController != null) ...[
                  const SizedBox(height: 16),
                  Text('Who is it for? (optional)', style: _ts(12.5, FontWeight.w600, _text(isDark))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: labelController,
                    maxLength: 60,
                    textCapitalization: TextCapitalization.words,
                    style: _ts(14, FontWeight.w500, _text(isDark)),
                    decoration: InputDecoration(
                      hintText: 'e.g. Dr. Rao, second opinion',
                      counterText: '',
                      hintStyle: _ts(13, FontWeight.w400, _muted(isDark)),
                      filled: true,
                      fillColor: _page(isDark),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _line(isDark))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _line(isDark))),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text('How long?', style: _ts(12.5, FontWeight.w600, _text(isDark))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final o in options) ...[
                      Expanded(
                        child: ChoiceChip(
                          label: SizedBox(width: double.infinity, child: Text(o.$2, textAlign: TextAlign.center)),
                          selected: selected == o.$1,
                          showCheckmark: false,
                          onSelected: (_) => setSheet(() => selected = o.$1),
                          labelStyle: _ts(13, selected == o.$1 ? FontWeight.w700 : FontWeight.w500, selected == o.$1 ? Colors.white : _text(isDark)),
                          selectedColor: _blue,
                          backgroundColor: _card(isDark),
                          side: BorderSide(color: selected == o.$1 ? _blue : _line(isDark)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                      if (o != options.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(confirm, style: _ts(15, FontWeight.w700, Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _confirm({required String title, required String message, required String confirm}) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _Sheet(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: _ts(17, FontWeight.w700, _text(isDark))),
            const SizedBox(height: 6),
            Text(message, style: _ts(12.5, FontWeight.w400, _muted(isDark), height: 1.45)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      foregroundColor: _text(isDark),
                      side: BorderSide(color: _line(isDark)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel', style: _ts(14, FontWeight.w600, _text(isDark))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(confirm, style: _ts(14, FontWeight.w700, Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return result == true;
  }

  // ─── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: _page(isDark),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _card(isDark),
        centerTitle: true,
        leading: IconButton(
          icon: PhosphorIcon(PhosphorIconsBold.caretLeft, size: 20, color: _text(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Share my profile', style: _ts(17, FontWeight.w700, _text(isDark))),
      ),
      body: RefreshIndicator(
        color: _blue,
        onRefresh: () => Future.wait([_loadDoctors(), _loadLinks()]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text('Who are you sharing with?', style: _ts(15, FontWeight.w700, _text(isDark))),
            const SizedBox(height: 10),
            Row(
              children: [
                _optionCard(
                  isDark,
                  index: 0,
                  icon: PhosphorIconsDuotone.stethoscope,
                  title: 'Doctor on Yira',
                  subtitle: 'Share in their app',
                ),
                const SizedBox(width: 10),
                _optionCard(
                  isDark,
                  index: 1,
                  icon: PhosphorIconsDuotone.link,
                  title: 'Any other doctor',
                  subtitle: 'Send a web link',
                ),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _option == 0
                  ? KeyedSubtree(key: const ValueKey('doctors'), child: _doctorsSection(isDark))
                  : KeyedSubtree(key: const ValueKey('links'), child: _linksSection(isDark)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(bool isDark, {required int index, required IconData icon, required String title, required String subtitle}) {
    final selected = _option == index;
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        child: Material(
          color: selected ? _blue.withValues(alpha: isDark ? 0.18 : 0.06) : _card(isDark),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() => _option = index),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? _blue : _line(isDark), width: selected ? 1.6 : 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? _blue : _blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: PhosphorIcon(icon, size: 22, color: selected ? Colors.white : _blue, duotoneSecondaryOpacity: 0.35),
                  ),
                  const SizedBox(height: 10),
                  Text(title, style: _ts(13.5, FontWeight.w700, _text(isDark))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: _ts(11.5, FontWeight.w500, _muted(isDark))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _note(bool isDark, IconData icon, String text, {Color color = _blue}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: PhosphorIcon(icon, size: 16, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: _ts(12, FontWeight.w500, isDark ? Colors.white70 : const Color(0xFF334155), height: 1.4))),
        ],
      ),
    );
  }

  Widget _doctorsSection(bool isDark) {
    final withAccess = _doctors.where((d) => d.hasAccess).toList();
    final others = _doctors.where((d) => !d.hasAccess).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _note(
          isDark,
          PhosphorIconsBold.info,
          "Doctors at a hospital you've visited can already see the records made there. Share your profile so a doctor can also see your history from other hospitals.",
        ),
        const SizedBox(height: 12),
        Material(
          color: _card(isDark),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              await Navigator.pushNamed(context, AppRoutes.patientConsentsScreen,
                  arguments: GlobalSession.instance.userNotifier.value?.data?.id);
              if (mounted) _loadDoctors();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: _line(isDark))),
              child: Row(
                children: [
                  const PhosphorIcon(PhosphorIconsDuotone.bellRinging, size: 22, color: _amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Requests from doctors', style: _ts(13.5, FontWeight.w700, _text(isDark))),
                        Text('Approve or decline doctors who asked to see your records', style: _ts(11.5, FontWeight.w400, _muted(isDark))),
                      ],
                    ),
                  ),
                  PhosphorIcon(PhosphorIconsBold.caretRight, size: 16, color: _muted(isDark)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (_loadingDoctors)
          const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: _blue)))
        else if (_doctorsError != null)
          _errorCard(isDark, _doctorsError!, _loadDoctors)
        else if (_doctors.isEmpty)
          _emptyCard(
            isDark,
            PhosphorIconsDuotone.stethoscope,
            'No doctors yet',
            'Doctors you book with or connect to by scanning their QR code will appear here.',
          )
        else ...[
          if (withAccess.isNotEmpty) ...[
            _label(isDark, 'SHARING WITH'),
            for (final d in withAccess) _doctorTile(isDark, d),
            const SizedBox(height: 14),
          ],
          if (others.isNotEmpty) ...[
            _label(isDark, 'YOUR DOCTORS'),
            for (final d in others) _doctorTile(isDark, d),
          ],
        ],
      ],
    );
  }

  Widget _doctorTile(bool isDark, ShareableDoctor d) {
    final busy = _busy.contains(d.id);
    final sub = d.hasAccess
        ? (d.accessUntil == null ? 'Can see your full history' : 'Can see your full history until ${_dateTime.format(d.accessUntil!)}')
        : [d.specialty, d.hospitalName].where((s) => s.trim().isNotEmpty).join(' · ');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: d.hasAccess ? _green.withValues(alpha: 0.4) : _line(isDark)),
      ),
      child: Row(
        children: [
          EntityLogo(imageUrl: d.photoUrl, name: d.name, size: 44, radius: 22, isLogo: false),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(14, FontWeight.w700, _text(isDark))),
                if (sub.isNotEmpty)
                  Text(sub, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: _ts(11.5, FontWeight.w500, d.hasAccess ? _green : _muted(isDark))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (busy)
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
          else if (d.hasAccess)
            TextButton(
              onPressed: d.consentId == null ? null : () => _stopAccess(d),
              style: TextButton.styleFrom(foregroundColor: _red, minimumSize: const Size(0, 36)),
              child: Text('Stop', style: _ts(13, FontWeight.w700, _red)),
            )
          else
            FilledButton(
              onPressed: () => _giveAccess(d),
              style: FilledButton.styleFrom(
                backgroundColor: _blue.withValues(alpha: isDark ? 0.22 : 0.1),
                foregroundColor: _blue,
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Share', style: _ts(13, FontWeight.w700, _blue)),
            ),
        ],
      ),
    );
  }

  Widget _linksSection(bool isDark) {
    final active = _links.where((l) => l.isActive).toList();
    final past = _links.where((l) => !l.isActive).take(5).toList();
    final creating = _busy.contains('new-link');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _note(
          isDark,
          PhosphorIconsBold.globe,
          "For a doctor who doesn't use Yira. They open the link in any browser, without logging in, and see all your health data: medicines, prescriptions, records, doctor notes, documents, visits, diet plans and fitness.",
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: creating ? null : _createLink,
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: creating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const PhosphorIcon(PhosphorIconsBold.linkSimple, size: 18, color: Colors.white),
            label: Text('Create a web link', style: _ts(15, FontWeight.w700, Colors.white)),
          ),
        ),
        const SizedBox(height: 18),
        if (_loadingLinks)
          const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: _blue)))
        else if (_linksError != null)
          _errorCard(isDark, _linksError!, _loadLinks)
        else ...[
          _label(isDark, active.isEmpty ? 'NO OPEN LINKS' : 'OPEN LINKS'),
          if (active.isEmpty)
            Text('Links you create appear here, so you can see when they were opened and turn them off.',
                style: _ts(12, FontWeight.w400, _muted(isDark), height: 1.4))
          else
            for (final l in active) _linkTile(isDark, l),
          if (past.isNotEmpty) ...[
            const SizedBox(height: 14),
            _label(isDark, 'PAST LINKS'),
            for (final l in past) _linkTile(isDark, l),
          ],
        ],
      ],
    );
  }

  Widget _linkTile(bool isDark, ProfileShareLink l) {
    final busy = _busy.contains('link-${l.id}');
    final opened = l.viewCount == 0
        ? 'Not opened yet'
        : 'Opened ${l.viewCount} ${l.viewCount == 1 ? 'time' : 'times'}${l.lastViewedAt == null ? '' : ', last ${_dateTime.format(l.lastViewedAt!)}'}';
    final state = switch (l.status) {
      'REVOKED' => 'Turned off',
      'EXPIRED' => 'Expired',
      _ => l.expiresAt == null ? 'Open' : 'Open until ${_dateTime.format(l.expiresAt!)}',
    };
    return Opacity(
      opacity: l.isActive ? 1 : 0.6,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _card(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line(isDark)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: (l.isActive ? _green : _muted(isDark)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: PhosphorIcon(PhosphorIconsBold.linkSimple, size: 18, color: l.isActive ? _green : _muted(isDark)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.label ?? 'Web link · made ${l.createdAt == null ? '' : _date.format(l.createdAt!)}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: _ts(13.5, FontWeight.w700, _text(isDark))),
                  Text(state, style: _ts(11.5, FontWeight.w600, l.isActive ? _green : _muted(isDark))),
                  Text(opened, style: _ts(11.5, FontWeight.w400, _muted(isDark))),
                ],
              ),
            ),
            if (l.isActive)
              busy
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: () => _revokeLink(l),
                      style: TextButton.styleFrom(foregroundColor: _red, minimumSize: const Size(0, 36)),
                      child: Text('Turn off', style: _ts(13, FontWeight.w700, _red)),
                    ),
          ],
        ),
      ),
    );
  }

  Widget _label(bool isDark, String text) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8),
        child: Text(text, style: _ts(11.5, FontWeight.w700, _muted(isDark)).copyWith(letterSpacing: 0.6)),
      );

  Widget _errorCard(bool isDark, String message, VoidCallback retry) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: _card(isDark), borderRadius: BorderRadius.circular(14), border: Border.all(color: _line(isDark))),
        child: Column(
          children: [
            const PhosphorIcon(PhosphorIconsDuotone.cloudSlash, size: 32, color: _amber),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: _ts(12.5, FontWeight.w500, _muted(isDark), height: 1.4)),
            TextButton(onPressed: retry, child: Text('Try again', style: _ts(13, FontWeight.w700, _blue))),
          ],
        ),
      );

  Widget _emptyCard(bool isDark, IconData icon, String title, String message) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _card(isDark), borderRadius: BorderRadius.circular(14), border: Border.all(color: _line(isDark))),
        child: Column(
          children: [
            PhosphorIcon(icon, size: 36, color: _blue),
            const SizedBox(height: 8),
            Text(title, style: _ts(14.5, FontWeight.w700, _text(isDark))),
            const SizedBox(height: 4),
            Text(message, textAlign: TextAlign.center, style: _ts(12, FontWeight.w400, _muted(isDark), height: 1.4)),
          ],
        ),
      );
}

class _Sheet extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _Sheet({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: _line(isDark), borderRadius: BorderRadius.circular(2)),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
