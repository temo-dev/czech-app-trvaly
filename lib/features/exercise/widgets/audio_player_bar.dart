import 'package:flutter/material.dart';
import 'package:app_czech/core/theme/app_colors.dart';
import 'package:app_czech/core/theme/app_spacing.dart';
import 'package:app_czech/core/theme/app_typography.dart';

enum AudioPlayerState { idle, loading, playing, paused, error }

/// Audio playback bar.
/// Full audio engine wired Day 11; this handles the UI state machine.
class AudioPlayerBar extends StatefulWidget {
  const AudioPlayerBar({
    super.key,
    required this.audioUrl,
    this.onPlayPause,
    this.maxPlays,     // null = unlimited
  });

  final String audioUrl;
  final VoidCallback? onPlayPause;
  final int? maxPlays;

  @override
  State<AudioPlayerBar> createState() => _AudioPlayerBarState();
}

class _AudioPlayerBarState extends State<AudioPlayerBar> {
  AudioPlayerState _state = AudioPlayerState.idle;
  int _playCount = 0;
  double _progress = 0.0;

  bool get _canPlay =>
      widget.maxPlays == null || _playCount < widget.maxPlays!;

  void _toggle() {
    if (!_canPlay) return;
    setState(() {
      if (_state == AudioPlayerState.playing) {
        _state = AudioPlayerState.paused;
      } else {
        _state = AudioPlayerState.playing;
        _playCount++;
      }
    });
    widget.onPlayPause?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPlaying = _state == AudioPlayerState.playing;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4, vertical: AppSpacing.x3),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Play/pause button
              GestureDetector(
                onTap: _canPlay ? _toggle : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _canPlay ? AppColors.primary : cs.outlineVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x3),
              // Progress + label
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stateLabel(),
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.x1),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: isPlaying ? _progress : null,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.2),
                        color: AppColors.primary,
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.maxPlays != null) ...[
                const SizedBox(width: AppSpacing.x3),
                Text(
                  'Còn ${(widget.maxPlays! - _playCount).clamp(0, widget.maxPlays!)} lần',
                  style: AppTypography.labelSmall
                      .copyWith(color: AppColors.primary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _stateLabel() => switch (_state) {
        AudioPlayerState.idle => 'Nhấn để nghe',
        AudioPlayerState.loading => 'Đang tải...',
        AudioPlayerState.playing => 'Đang phát...',
        AudioPlayerState.paused => 'Tạm dừng',
        AudioPlayerState.error => 'Lỗi phát âm thanh',
      };
}
