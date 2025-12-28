import 'package:flutter/material.dart';

class Song {
  final String id;
  final String title;
  final String filePath;
  String? connectedNfcUuid;

  Song({
    required this.id,
    required this.title,
    required this.filePath,
    this.connectedNfcUuid,
  });

  // Convert the song to a JSON map
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'filePath': filePath,
    'connectedNfcUuid': connectedNfcUuid,
  };

  // Create a song from a JSON map
  factory Song.fromJson(Map<String, dynamic> json) => Song(
    id: json['id'],
    title: json['title'],
    filePath: json['filePath'],
    connectedNfcUuid: json['connectedNfcUuid'],
  );
}

class SongProvider with ChangeNotifier {
  final List<Song> _songs = [];

  List<Song> get songs => _songs;

  void addSong(Song song) {
    _songs.add(song);
    notifyListeners();
  }

  void removeSong(String songId) {
    _songs.removeWhere((song) => song.id == songId);
    notifyListeners();
  }

  void connectSongToNfc(String songId, String nfcUuid) {
    final songIndex = _songs.indexWhere((song) => song.id == songId);
    if (songIndex != -1) {
      _songs[songIndex] = Song(
        id: _songs[songIndex].id,
        title: _songs[songIndex].title,
        filePath: _songs[songIndex].filePath,
        connectedNfcUuid: nfcUuid,
      );
      notifyListeners();
    }
  }

  void disconnectSongFromNfc(String songId) {
    final songIndex = _songs.indexWhere((song) => song.id == songId);
    if (songIndex != -1) {
      _songs[songIndex] = Song(
        id: _songs[songIndex].id,
        title: _songs[songIndex].title,
        filePath: _songs[songIndex].filePath,
        connectedNfcUuid: null,
      );
      notifyListeners();
    }
  }

  Song? getSongByNfcUuid(String nfcUuid) {
    return _songs.firstWhere(
      (song) => song.connectedNfcUuid == nfcUuid,
      orElse: () => Song(id: '', title: '', filePath: '', connectedNfcUuid: null),
    );
  }
}