import 'package:flutter/material.dart';

import '../data/repository.dart';
import 'glass.dart';
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  GlassHero(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Icon(Icons.home_rounded,
                              color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'بيتي',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'تتبع مشتريات ونواقص العائلة',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GlassSurface(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionLabel(
                          icon: Icons.add_circle_outline,
                          label: 'ابدأ قائمة جديدة',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _busy ? null : _create,
                          icon: const Icon(Icons.add),
                          label: const Text('إنشاء قائمة بيت'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GlassSurface(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SectionLabel(
                          icon: Icons.vpn_key_outlined,
                          label: 'لديك رمز دعوة؟',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _joinCtrl,
                          textDirection: TextDirection.ltr,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            hintText: 'أدخل الرمز أو الصق الرابط',
                            prefixIcon: Icon(Icons.link, size: 20),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _join,
                          icon: const Icon(Icons.group_add),
                          label: const Text('الانضمام للقائمة'),
                        ),
                      ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: BaytiColors.primaryDark),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: BaytiColors.text,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
