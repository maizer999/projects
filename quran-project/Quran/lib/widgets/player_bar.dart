import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../services/player_controller.dart';
import '../theme.dart';

class PlayerBar extends StatefulWidget {
  const PlayerBar({super.key, required this.state, required this.player});
  final AppState state;
  final PlayerController player;

  @override
  State<PlayerBar> createState() => _PlayerBarState();
}

class _PlayerBarState extends State<PlayerBar> {
  @override
  void initState() {
    super.initState();
    widget.player.changes.listen((_) {
      if (mounted) setState(() {});
    });
    widget.state.addListener(_onState);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final arabic = s.arabic!;
    final total = widget.player.duration.inMilliseconds.toDouble();
    final pos = widget.player.position.inMilliseconds.toDouble();
    final value = total > 0 ? (pos / total).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: s.darkMode ? AppColors.bg2Dark : AppColors.panelLight,
        border: Border(
          top: BorderSide(
            color: s.darkMode ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                _fmt(widget.player.position),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedDark,
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: value,
                    onChanged: total > 0
                        ? (v) {
                            widget.player.seek(
                              Duration(milliseconds: (v * total).round()),
                            );
                          }
                        : null,
                  ),
                ),
              ),
              Text(
                _fmt(widget.player.duration),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.mutedDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: widget.player.previous,
              ),
              Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.accent, AppColors.accent2],
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    s.playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: widget.player.toggle,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: widget.player.next,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${arabic.englishName} · ${arabic.name}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      s.currentAyahIdx >= 0
                          ? 'Ayah ${arabic.ayahs[s.currentAyahIdx].numberInSurah} · ${s.currentReciter.name}'
                          : s.currentReciter.name,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.mutedDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.stop),
                onPressed: widget.player.stop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
