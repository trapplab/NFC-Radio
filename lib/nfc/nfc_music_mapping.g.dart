// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nfc_music_mapping.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class NFCMusicMappingAdapter extends TypeAdapter<NFCMusicMapping> {
  @override
  final int typeId = 1;

  @override
  NFCMusicMapping read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NFCMusicMapping(
      nfcUuid: fields[0] as String,
      songId: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, NFCMusicMapping obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.nfcUuid)
      ..writeByte(1)
      ..write(obj.songId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NFCMusicMappingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
