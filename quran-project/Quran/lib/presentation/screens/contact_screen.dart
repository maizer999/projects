import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/api_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/contact_constants.dart';
import '../../core/theme/app_colors.dart';

/// "تواصل معنا": email, phone and WhatsApp cards, plus a message form that
/// opens the mail app pre-filled.
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _nameCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String? _msgError;

  static const _emailColor = Color(0xFF3B82F6);
  static const _phoneColor = Color(0xFF22C55E);
  static const _whatsappColor = Color(0xFF25D366);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _open(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _toast(AppStrings.cannotOpenApp);
  }

  void _copy(String value, String what) {
    Clipboard.setData(ClipboardData(text: value));
    _toast(AppStrings.copied(what));
  }

  void _toast(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(text, textDirection: TextDirection.rtl),
        behavior: SnackBarBehavior.floating,
        duration: AppConstants.snackBarDuration,
      ));
  }

  void _send() {
    final msg = _msgCtrl.text.trim();
    if (msg.isEmpty) {
      setState(() => _msgError = AppStrings.messageRequired);
      return;
    }
    final name = _nameCtrl.text.trim();
    final body = name.isEmpty ? msg : '$msg\n\n— $name';
    // mailto needs %20 for spaces, not "+", so encode by hand.
    final query = {
      'subject': ContactConstants.emailSubject,
      'body': body,
    }.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    _open(Uri(scheme: 'mailto', path: ContactConstants.email, query: query));
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.panelDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
      );

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            AppStrings.contactUs,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _intro(),
              const SizedBox(height: 16),
              _ContactTile(
                icon: Icons.mail_outline,
                color: _emailColor,
                title: AppStrings.email,
                value: ContactConstants.email,
                ltrValue: true,
                onTap: () => _open(Uri(scheme: 'mailto', path: ContactConstants.email)),
                onCopy: () => _copy(ContactConstants.email, AppStrings.emailNoun),
              ),
              const SizedBox(height: 10),
              _ContactTile(
                icon: Icons.phone_outlined,
                color: _phoneColor,
                title: AppStrings.phone,
                value: ContactConstants.phone,
                ltrValue: true,
                onTap: () => _open(Uri(scheme: 'tel', path: ContactConstants.phone)),
                onCopy: () => _copy(ContactConstants.phone, AppStrings.phoneNoun),
              ),
              const SizedBox(height: 10),
              _ContactTile(
                icon: Icons.chat_outlined,
                color: _whatsappColor,
                title: AppStrings.whatsapp,
                value: AppStrings.whatsappSubtitle,
                onTap: () =>
                    _open(Uri.parse('${ApiConstants.whatsappBase}/${ContactConstants.whatsapp}')),
              ),
              const SizedBox(height: 20),
              _form(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _intro() => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
              ),
              child: const Icon(Icons.support_agent, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.contactIntroTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.contactIntroBody,
                    style: TextStyle(fontSize: 13, color: AppColors.mutedDark),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _form() => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              AppStrings.sendMessage,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: AppStrings.nameHint,
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _msgCtrl,
              minLines: 4,
              maxLines: 6,
              onChanged: (_) {
                if (_msgError != null) setState(() => _msgError = null);
              },
              decoration: InputDecoration(
                hintText: AppStrings.messageHint,
                errorText: _msgError,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _send,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.send, textDirection: TextDirection.ltr),
                label: const Text(
                  AppStrings.send,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      );
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onTap,
    this.onCopy,
    this.ltrValue = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onCopy;
  final bool ltrValue;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panelDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.15),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      textDirection: ltrValue ? TextDirection.ltr : TextDirection.rtl,
                      style: TextStyle(fontSize: 13, color: AppColors.mutedDark),
                    ),
                  ],
                ),
              ),
              if (onCopy != null)
                IconButton(
                  tooltip: AppStrings.copy,
                  icon: Icon(Icons.copy, size: 18, color: AppColors.mutedDark),
                  onPressed: onCopy,
                )
              else
                Icon(Icons.chevron_left, color: AppColors.mutedDark),
            ],
          ),
        ),
      ),
    );
  }
}
