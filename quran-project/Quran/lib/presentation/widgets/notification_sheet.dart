import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/dependency_providers.dart';
import '../providers/settings_provider.dart';

void showNotificationSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.bg2Dark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _NotificationSheet(),
  );
}

class _NotificationSheet extends ConsumerWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(settingsProvider.select((s) => s.notificationsEnabled));
    final ayahs = ref.watch(allMushafAyahsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_rounded, color: AppColors.accent2, size: 22),
                  const SizedBox(width: 10),
                  const Text(
                    'تذكير القرآن',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Switch(
                    value: enabled,
                    activeColor: AppColors.accent2,
                    onChanged: (v) =>
                        ref.read(settingsProvider.notifier).setNotifications(v, ayahs),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'يصلك تذكير كل ٣٠ دقيقة بآيات من القرآن الكريم.',
                style: TextStyle(fontSize: 13, color: AppColors.mutedDark),
              ),
              const SizedBox(height: 4),
              Text(
                enabled ? '✓ التذكيرات مفعّلة' : 'التذكيرات متوقفة',
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? AppColors.accent2 : AppColors.mutedDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
