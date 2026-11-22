import 'package:flutter/material.dart';

import '../data/repository.dart';
import 'list_screen.dart';
import 'theme.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key, required this.repo});
  final ListRepository repo;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _joinCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _joinCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      final list = await widget.repo.createList();
      if (!mounted) return;
      _openList(list.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إنشاء القائمة. تحقق من الاتصال.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final raw = _joinCtrl.text.trim();
    if (raw.isEmpty) return;
    setState(() => _busy = true);
    try {
      final code = _extractCode(raw);
      final joined = await widget.repo.joinViaCode(code);
      if (!mounted) return;
      if (joined == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رمز الدعوة غير صحيح')),
        );
        return;
      }
      _openList(joined.id);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _extractCode(String input) {
    final uri = Uri.tryParse(input);
    if (uri != null) {
      final q = uri.queryParameters['code'] ?? uri.queryParameters['list'];
      if (q != null && q.isNotEmpty) return q.trim().toUpperCase();
    }
    return input.toUpperCase();
  }

  void _openList(String id) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ListScreen(repo: widget.repo, listId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.bPrimary;
    return Scaffold(
      backgroundColor: BaytiColors.bg,
      body: Stack(
        children: [
          _backdrop(primary),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                    decoration: BoxDecoration(
                      color: BaytiColors.card,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: BaytiColors.line),
                      boxShadow: BaytiShadows.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LogoMark(primary: primary),
                        const SizedBox(height: 20),
                        Text(
                          'بيتي',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(
                                fontSize: 36,
                                color: context.bPrimaryDark,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'متتبع مشتريات ونواقص العائلة — شارك الرابط مع أفراد العائلة، والجميع يرى ويعدّل نفس القائمة.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: BaytiColors.muted,
                                height: 1.75,
                                fontSize: 14.5,
                              ),
                        ),
                        const SizedBox(height: 32),
                        _bigCreateButton(),
                        const SizedBox(height: 24),
                        const _Divider(label: 'أو'),
                        const SizedBox(height: 20),
                        _joinBlock(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _backdrop(Color primary) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -80,
              child: _blob(primary.withValues(alpha: 0.08), 280),
            ),
            Positioned(
              bottom: -140,
              left: -100,
              child: _blob(context.bAccent.withValues(alpha: 0.18), 340),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(Color color, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      );

  Widget _bigCreateButton() {
    final primary = context.bPrimary;
    return Opacity(
      opacity: _busy ? 0.6 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(60),
          boxShadow: _busy
              ? const []
              : [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.32),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Material(
          color: primary,
          shape: const StadiumBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: _busy ? null : _create,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 36, vertical: 18),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_busy) ...[
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    const Icon(Icons.add_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                  ],
                  const Text(
                    'إنشاء قائمة جديدة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.5,
                      fontWeight: FontWeight.w700,
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

  Widget _joinBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'لديك رمز دعوة؟',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: BaytiColors.muted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _joinCtrl,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
          decoration: const InputDecoration(
            hintText: 'أدخل الرمز أو الصق الرابط',
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _busy ? null : _join,
          icon: const Icon(Icons.group_add_rounded, size: 18),
          label: const Text('الانضمام للقائمة'),
        ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.primary});
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            Color.lerp(primary, Colors.black, 0.18) ?? primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.home_rounded,
        color: Colors.white,
        size: 44,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: BaytiColors.line)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: const TextStyle(
              color: BaytiColors.placeholder,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: BaytiColors.line)),
      ],
    );
  }
}