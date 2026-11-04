// Guards against users losing their data on app updates.
//
// test/fixtures/hive_v2_2_3/ holds box files written by the original
// `hive` 2.2.3 package with the adapters the app shipped up to 1.0.0
// (including a folder record from early app versions with only fields 0-4).
// These tests open them with the current storage code and adapters.
// Never regenerate the fixtures with the current code - they must stay
// the old format.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:nfc_radio/nfc/nfc_music_mapping.dart';
import 'package:nfc_radio/storage/folder.dart';
import 'package:nfc_radio/storage/song.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_compat_');
    final fixtures = Directory('test/fixtures/hive_v2_2_3');
    for (final file in fixtures.listSync().whereType<File>()) {
      file.copySync('${tempDir.path}/${file.uri.pathSegments.last}');
    }
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(SongAdapter());
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(NFCMusicMappingAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(FolderAdapter());
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('reads songs written by hive 2.x', () async {
    final box = await Hive.openBox<Song>('songs');
    expect(box.length, 2);

    final s1 = box.get('s1')!;
    expect(s1.id, 's1');
    expect(s1.title, 'Gruffalo');
    expect(s1.filePath, '/storage/emulated/0/Audio/gruffalo.mp3');
    expect(s1.connectedNfcUuid, 'e0:04:01:50:12:34:56:78');
    expect(s1.isLoopEnabled, isTrue);
    expect(s1.rememberPosition, isTrue);
    expect(s1.savedPositionMs, 123456);

    final s2 = box.get('s2')!;
    expect(s2.connectedNfcUuid, isNull);
    expect(s2.isLoopEnabled, isFalse);
    expect(s2.savedPositionMs, isNull);
  });

  test('reads NFC mappings written by hive 2.x', () async {
    final box = await Hive.openBox<NFCMusicMapping>('mappings');
    final m = box.get('e0:04:01:50:12:34:56:78')!;
    expect(m.nfcUuid, 'e0:04:01:50:12:34:56:78');
    expect(m.songId, 's1');
  });

  test('reads folders written by hive 2.x, incl. legacy records', () async {
    final box = await Hive.openBox<Folder>('folders');
    expect(box.length, 3);

    final f1 = box.get('f1')!;
    expect(f1.name, 'Bedtime');
    expect(f1.songIds, ['s1', 's2']);
    expect(f1.isExpanded, isTrue);
    expect(f1.connectedNfcUuid, '04:a1:b2:c3:d4:e5:f6');
    expect(f1.isShuffleEnabled, isTrue);
    expect(f1.isLoopPlaylistEnabled, isTrue);
    expect(f1.lastPlayedSongIndex, 1);
    expect(f1.lastPlayedPositionMs, 98765);
    expect(f1.nfcSkipsToNext, isTrue);
    expect(f1.parentFolderId, isNull);

    expect(box.get('f2')!.parentFolderId, 'f1');

    // Record from an early app version: only fields 0-4 stored.
    final f0 = box.get('f0')!;
    expect(f0.name, 'Old folder');
    expect(f0.songIds, ['s2']);
    expect(f0.position, 2);
    expect(f0.isShuffleEnabled, isFalse);
    expect(f0.isLoopPlaylistEnabled, isFalse);
    expect(f0.nfcSkipsToNext, isFalse);
    expect(f0.lastPlayedSongIndex, isNull);
    expect(f0.parentFolderId, isNull);
  });

  test('reads settings written by hive 2.x', () async {
    final box = await Hive.openBox<dynamic>('settings');
    expect(box.get('filter_audio_only'), isFalse);
    expect(box.get('use_system_overlay'), isTrue);
    expect(box.get('show_audio_controls_on_lockscreen'), isTrue);
    expect(box.get('sleep_timer_duration_minutes'), 45);
    expect(box.get('auto_sleep_timer_enabled'), isTrue);
    expect(box.get('auto_sleep_timer_restrict_hours'), isTrue);
    expect(box.get('auto_sleep_timer_start_hour'), 20);
    expect(box.get('auto_sleep_timer_end_hour'), 7);
    // Setting added in 1.1.0 is absent in old data -> default applies.
    expect(box.get('pause_on_tag_removal', defaultValue: false), isFalse);
  });

  test('old data stays readable after being rewritten', () async {
    final box = await Hive.openBox<Folder>('folders');
    final f0 = box.get('f0')!;
    f0.name = 'Renamed';
    await f0.save();
    await box.compact();
    await Hive.close();

    Hive.init(tempDir.path);
    final reopened = await Hive.openBox<Folder>('folders');
    expect(reopened.get('f0')!.name, 'Renamed');
    expect(reopened.get('f1')!.songIds, ['s1', 's2']);
  });
}
