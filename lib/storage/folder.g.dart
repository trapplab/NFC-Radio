// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FolderAdapter extends TypeAdapter<Folder> {
  @override
  final typeId = 2;

  @override
  Folder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Folder(
      id: fields[0] == null ? '' : fields[0] as String,
      name: fields[1] == null ? 'New Folder' : fields[1] as String,
      songIds: fields[2] == null ? [] : (fields[2] as List).cast<String>(),
      isExpanded: fields[3] == null ? false : fields[3] as bool,
      position: fields[4] == null ? 0 : (fields[4] as num).toInt(),
      connectedNfcUuid: fields[5] as String?,
      isShuffleEnabled: fields[6] == null ? false : fields[6] as bool,
      isLoopPlaylistEnabled: fields[7] == null ? false : fields[7] as bool,
      lastPlayedSongIndex: (fields[8] as num?)?.toInt(),
      lastPlayedPositionMs: (fields[9] as num?)?.toInt(),
      nfcSkipsToNext: fields[10] == null ? false : fields[10] as bool,
      parentFolderId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Folder obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.songIds)
      ..writeByte(3)
      ..write(obj.isExpanded)
      ..writeByte(4)
      ..write(obj.position)
      ..writeByte(5)
      ..write(obj.connectedNfcUuid)
      ..writeByte(6)
      ..write(obj.isShuffleEnabled)
      ..writeByte(7)
      ..write(obj.isLoopPlaylistEnabled)
      ..writeByte(8)
      ..write(obj.lastPlayedSongIndex)
      ..writeByte(9)
      ..write(obj.lastPlayedPositionMs)
      ..writeByte(10)
      ..write(obj.nfcSkipsToNext)
      ..writeByte(11)
      ..write(obj.parentFolderId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FolderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
