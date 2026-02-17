import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as p;
import 'music_player.dart';
import 'sleep_timer_service.dart';
import '../config/theme_provider.dart';
import '../l10n/app_localizations.dart';

class PlayerWidget extends StatelessWidget {
  final bool isLockscreen;

  const PlayerWidget({
    this.isLockscreen = false,
    super.key,
  });

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

        final Color backgroundColor = isLockscreen 
            ? themeProvider.footerColor 
            : themeProvider.footerColor;
        final Color borderColor = isLockscreen 
            ? themeProvider.bannerColor 
            : themeProvider.bannerColor;
        final Color textColor = isLockscreen ? Colors.white : Colors.black;
        final Color subtextColor = isLockscreen ? Colors.white70 : Colors.black54;
        final Color iconColor = isLockscreen ? Colors.white : Colors.black;

        return Dismissible(
          key: const ValueKey('player_widget'),
          direction: DismissDirection.horizontal,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            child: const Icon(Icons.stop_circle_outlined, color: Colors.red),
          ),
          secondaryBackground: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.stop_circle_outlined, color: Colors.red),
          ),
          onDismissed: (_) => musicPlayer.stopMusic(),
          child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isLockscreen ? null : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context)!.nowPlaying(
                  musicPlayer.currentSongTitle ?? _getDisplayName(musicPlayer.currentMusicFilePath)
                ),
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                overflow: TextOverflow.ellipsis,
              ),
              if (musicPlayer.totalDuration > Duration.zero)
                Text(
                  AppLocalizations.of(context)!.positionWithTotal(
                    musicPlayer.getCurrentPositionString(),
                    musicPlayer.getTotalDurationString(),
                  ),
                  style: TextStyle(fontSize: 12, color: subtextColor),
                ),
              if (sleepTimer.isActive)
                GestureDetector(
                  onTap: () {
                    sleepTimer.cancel();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context)!.sleepTimerCancelled),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bedtime, size: 14, color: subtextColor),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.of(context)!.sleepTimerRemaining(sleepTimer.formatRemaining()),
                          style: TextStyle(fontSize: 12, color: subtextColor),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (musicPlayer.isPlaylistMode)
                    IconButton(
                      onPressed: musicPlayer.hasPrevious ? musicPlayer.playPrevious : null,
                      icon: Icon(Icons.skip_previous, color: musicPlayer.hasPrevious ? iconColor : iconColor.withValues(alpha: 0.3)),
                    ),
                  IconButton(
                    onPressed: musicPlayer.togglePlayPause,
                    icon: Icon(
                      musicPlayer.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: iconColor,
                    ),
                    tooltip: musicPlayer.isPlaying ? 'Pause' : 'Play',
                  ),
                  if (musicPlayer.isPlaylistMode)
                    IconButton(
                      onPressed: musicPlayer.hasNext ? musicPlayer.playNext : null,
                      icon: Icon(Icons.skip_next, color: musicPlayer.hasNext ? iconColor : iconColor.withValues(alpha: 0.3)),
                    ),
                  if (musicPlayer.totalDuration > Duration.zero)
                    Expanded(
                      child: Slider(
                        value: musicPlayer.savedPosition.inSeconds.toDouble(),
                        min: 0,
                        max: musicPlayer.totalDuration.inSeconds.toDouble(),
                        onChangeStart: (_) {
                          musicPlayer.setSeeking(true);
                        },
                        onChanged: (value) {
                          musicPlayer.seekTo(Duration(seconds: value.toInt()));
                        },
                        onChangeEnd: (value) {
                          musicPlayer.seekTo(Duration(seconds: value.toInt()), persist: true);
                          musicPlayer.setSeeking(false);
                        },
                        activeColor: themeProvider.bannerColor,
                        inactiveColor: isLockscreen ? Colors.white30 : Colors.black12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ), // end Container (Dismissible child)
        ); // end Dismissible
      },
    );
  }
}
