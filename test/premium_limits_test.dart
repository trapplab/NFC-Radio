import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_radio/folder.dart';
import 'package:nfc_radio/song.dart';

void main() {
  group('Premium Limits Test', () {
    late FolderProvider folderProvider;
    
    setUp(() {
      folderProvider = FolderProvider();
    });

    test('Restricted version should limit folders to 2', () async {
      // Simulate the restricted version (Google Play)
      folderProvider.setRestrictedVersion(true);
      
      // Add 2 folders (should succeed)
      folderProvider.addFolder(Folder(id: '1', name: 'Folder 1', songIds: []));
      folderProvider.addFolder(Folder(id: '2', name: 'Folder 2', songIds: []));
      
      expect(folderProvider.folders.length, 2);
      
      // Try to add a 3rd folder (should fail)
      folderProvider.addFolder(Folder(id: '3', name: 'Folder 3', songIds: []));
      
      expect(folderProvider.folders.length, 2); // Should still be 2
    });

    test('Unrestricted version should allow unlimited folders', () async {
      // Simulate the unrestricted version (F-Droid)
      folderProvider.setRestrictedVersion(false);
      
      // Add 3 folders (should succeed)
      folderProvider.addFolder(Folder(id: '1', name: 'Folder 1', songIds: []));
      folderProvider.addFolder(Folder(id: '2', name: 'Folder 2', songIds: []));
      folderProvider.addFolder(Folder(id: '3', name: 'Folder 3', songIds: []));
      
      expect(folderProvider.folders.length, 3);
    });

    test('Restricted version should limit songs per folder to 6', () async {
      // Simulate the restricted version (Google Play)
      folderProvider.setRestrictedVersion(true);
      
      // Add a folder
      folderProvider.addFolder(Folder(id: '1', name: 'Folder 1', songIds: []));
      
      // Add 6 songs to the folder (should succeed)
      for (int i = 0; i < 6; i++) {
        folderProvider.addSongToFolder('1', 'song_$i');
      }
      
      expect(folderProvider.folders.first.songIds.length, 6);
      
      // Try to add a 7th song (should fail)
      folderProvider.addSongToFolder('1', 'song_6');
      
      expect(folderProvider.folders.first.songIds.length, 6); // Should still be 6
    });

    test('Unrestricted version should allow unlimited songs per folder', () async {
      // Simulate the unrestricted version (F-Droid)
      folderProvider.setRestrictedVersion(false);
      
      // Add a folder
      folderProvider.addFolder(Folder(id: '1', name: 'Folder 1', songIds: []));
      
      // Add 7 songs to the folder (should succeed)
      for (int i = 0; i < 7; i++) {
        folderProvider.addSongToFolder('1', 'song_$i');
      }
      
      expect(folderProvider.folders.first.songIds.length, 7);
    });
  });
}