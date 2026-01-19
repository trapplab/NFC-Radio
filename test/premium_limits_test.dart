import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_radio/folder.dart';

void main() {
  group('Premium Limits Test', () {
    late FolderProvider folderProvider;

    setUp(() {
      folderProvider = FolderProvider();
    });

    test('Adding folders should work for F-Droid/GitHub flavors', () async {
      // Note: In test environment, AppConfig.isGooglePlayRelease is false by default
      // So this should allow unlimited folders

      // Add 3 folders (should succeed)
      folderProvider.addFolder(Folder(id: '1', name: 'Folder 1', songIds: []));
      folderProvider.addFolder(Folder(id: '2', name: 'Folder 2', songIds: []));
      folderProvider.addFolder(Folder(id: '3', name: 'Folder 3', songIds: []));

      expect(folderProvider.folders.length, 3);
    });

    test('Adding songs should work for F-Droid/GitHub flavors', () async {
      // Note: In test environment, AppConfig.isGooglePlayRelease is false by default
      // So this should allow unlimited songs per folder

      // Add a folder
      folderProvider.addFolder(Folder(id: '1', name: 'Folder 1', songIds: []));

      // Add 7 songs to the folder (should succeed)
      for (int i = 0; i < 7; i++) {
        folderProvider.addSongToFolder('1', 'song_$i');
      }

      expect(folderProvider.folders.first.songIds.length, 7);
    });

    test('isFolderLimitReached returns false for non-restricted flavors', () async {
      // Add 2 folders
      folderProvider.addFolder(Folder(id: '1', name: 'Folder 1', songIds: []));
      folderProvider.addFolder(Folder(id: '2', name: 'Folder 2', songIds: []));

      // For non-Google Play flavors, limit should not be reached at 2 folders
      expect(folderProvider.isFolderLimitReached(), false);
    });

    test('isSongLimitReached returns false for non-restricted flavors', () async {
      // Add a folder
      folderProvider.addFolder(Folder(id: '1', name: 'Folder 1', songIds: []));

      // Add 6 songs
      for (int i = 0; i < 6; i++) {
        folderProvider.addSongToFolder('1', 'song_$i');
      }

      // For non-Google Play flavors, limit should not be reached
      expect(folderProvider.isSongLimitReached('1'), false);
    });
  });
}
