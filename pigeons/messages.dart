import 'package:pigeon/pigeon_lib.dart';

class TextureMessage {
  late int textureId;
}

class LoopingMessage {
  late int textureId;
  late bool isLooping;
}

class VolumeMessage {
  late int textureId;
  late double volume;
}

class PositionMessage {
  late int textureId;
  late int position;
}

class CreateMessage {
  late String asset;
  late String uri;
  late String packageName;
  late String formatHint;
}

@HostApi()
abstract class VideoPlayerApi {
  void initialize();
  TextureMessage create(CreateMessage msg);
  void dispose(TextureMessage msg);
  void setLooping(LoopingMessage msg);
  void setVolume(VolumeMessage msg);
  void play(TextureMessage msg);
  PositionMessage position(TextureMessage msg);
  void seekTo(PositionMessage msg);
  void pause(TextureMessage msg);
}

void configurePigeon(PigeonOptions opts) {
  opts.dartOut = '../video_player_platform_interface/lib/messages.dart';
  opts.objcHeaderOut = 'ios/Classes/messages.h';
  opts.objcSourceOut = 'ios/Classes/messages.m';
  opts.objcOptions.prefix = 'FLT';
  opts.javaOut =
      'android/src/main/java/io/flutter/plugins/videoplayer/Messages.java';
  opts.javaOptions.package = 'ext.videoplayer';
}
