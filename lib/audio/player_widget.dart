import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'music_player.dart';
import 'sleep_timer_service.dart';
import '../config/theme_provider.dart';
import '../storage/folder.dart';
import '../l10n/app_localizations.dart';

class PlayerWidget extends StatelessWidget {
  final bool isLockscreen;

  const PlayerWidget({this.isLockscreen = false, super.key});

  String _getDisplayName(String? path) {
    if (path == null || path.isEmpty) return 'Unknown';
    return p.basename(path);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeProvider, MusicPlayer, SleepTimerService>(
      builder: (context, themeProvider, musicPlayer, sleepTimer, child) {
        if (!musicPlayer.isPlaying && !musicPlayer.isPaused) {
          return const SizedBox.shrink();
        }

        final l10n = AppLocalizations.of(context)!;
        final scheme = Theme.of(context).colorScheme;
        final Color backgroundColor = isLockscreen
            ? themeProvider.footerColor
            : scheme.surfaceContainerHigh;
        final Color accent = isLockscreen
            ? themeProvider.bannerColor
            : scheme.primary;
        final Color textColor = isLockscreen ? Colors.white : scheme.onSurface;
        final Color subtextColor = isLockscreen
            ? Colors.white70
            : scheme.onSurfaceVariant;

        String? folderName;
        if (musicPlayer.isPlaylistMode) {
          final folderId = musicPlayer.currentPlaylistFolderId;
          folderName = Provider.of<FolderProvider>(
            context,
            listen: false,
          ).folders.firstWhereOrNull((f) => f.id == folderId)?.name;
          if (musicPlayer.playlistLength > 1) {
            final position =
                '${musicPlayer.currentPlaylistIndex + 1}/${musicPlayer.playlistLength}';
            folderName = folderName == null
                ? position
                : '$folderName · $position';
          }
        }

        final title =
            musicPlayer.currentSongTitle ??
            _getDisplayName(musicPlayer.currentMusicFilePath);
        final bool hasDuration = musicPlayer.totalDuration > Duration.zero;
        final double maxSeconds = musicPlayer.totalDuration.inSeconds
            .toDouble();
        final double currentSeconds = musicPlayer.savedPosition.inSeconds
            .toDouble()
            .clamp(0, maxSeconds > 0 ? maxSeconds : 0);

        return Dismissible(
          key: const ValueKey('player_widget'),
          direction: DismissDirection.horizontal,
          background: _buildDismissBackground(Alignment.centerLeft),
          secondaryBackground: _buildDismissBackground(Alignment.centerRight),
          onDismissed: (_) => musicPlayer.stopMusic(),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 4),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: isLockscreen
                  ? Border.all(color: themeProvider.bannerColor)
                  : null,
              boxShadow: isLockscreen
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        musicPlayer.isPlaylistMode
                            ? Icons.queue_music
                            : Icons.music_note,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          if (folderName != null)
                            Text(
                              folderName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: subtextColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (musicPlayer.isPlaylistMode)
                      IconButton(
                        onPressed: musicPlayer.hasPrevious
                            ? musicPlayer.playPrevious
                            : null,
                        icon: const Icon(Icons.skip_previous),
                        color: textColor,
                        disabledColor: textColor.withValues(alpha: 0.3),
                      ),
                    IconButton.filled(
                      onPressed: musicPlayer.togglePlayPause,
                      iconSize: 30,
                      style: IconButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(52, 52),
                      ),
                      icon: Icon(
                        musicPlayer.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      tooltip: musicPlayer.isPlaying ? l10n.pause : l10n.play,
                    ),
                    if (musicPlayer.isPlaylistMode)
                      IconButton(
                        onPressed: musicPlayer.hasNext
                            ? musicPlayer.playNext
                            : null,
                        icon: const Icon(Icons.skip_next),
                        color: textColor,
                        disabledColor: textColor.withValues(alpha: 0.3),
                      ),
                  ],
                ),
                if (hasDuration)
                  Row(
                    children: [
                      Text(
                        musicPlayer.getCurrentPositionString(),
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 16,
                            ),
                          ),
                          child: Slider(
                            value: currentSeconds,
                            min: 0,
                            max: maxSeconds,
                            onChangeStart: (_) {
                              musicPlayer.setSeeking(true);
                            },
                            onChanged: (value) {
                              musicPlayer.seekTo(
                                Duration(seconds: value.toInt()),
                              );
                            },
                            onChangeEnd: (value) {
                              musicPlayer.seekTo(
                                Duration(seconds: value.toInt()),
                                persist: true,
                              );
                              musicPlayer.setSeeking(false);
                            },
                            activeColor: accent,
                            inactiveColor: accent.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      Text(
                        musicPlayer.getTotalDurationString(),
                        style: TextStyle(fontSize: 11, color: subtextColor),
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                if (sleepTimer.isActive)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InputChip(
                      avatar: Icon(Icons.bedtime, size: 16, color: accent),
                      label: Text(
                        l10n.sleepTimerRemaining(sleepTimer.formatRemaining()),
                        style: TextStyle(fontSize: 12, color: textColor),
                      ),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 16,
                        color: subtextColor,
                      ),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(color: accent.withValues(alpha: 0.4)),
                      visualDensity: VisualDensity.compact,
                      onDeleted: () => _cancelSleepTimer(context, sleepTimer),
                      onPressed: () => _cancelSleepTimer(context, sleepTimer),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _cancelSleepTimer(BuildContext context, SleepTimerService sleepTimer) {
    sleepTimer.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.sleepTimerCancelled),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildDismissBackground(Alignment alignment) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: const Icon(Icons.stop_circle_outlined, color: Colors.red),
    );
  }
}
