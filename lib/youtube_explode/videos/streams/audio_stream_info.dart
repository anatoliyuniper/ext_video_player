import 'package:ext_video_player/youtube_explode/models/fragment.dart';
import 'package:http_parser/http_parser.dart';

import 'streams.dart';

/// YouTube media stream that contains audio.
abstract class AudioStreamInfo extends StreamInfo {
  /// Audio codec.
  final String audioCodec;

  ///
  AudioStreamInfo(
      int tag,
      Uri url,
      StreamContainer container,
      FileSize size,
      Bitrate bitrate,
      this.audioCodec,
      List<Fragment> fragments,
      MediaType codec,
      String qualityLabel)
      : super(
            tag, url, container, size, bitrate, fragments, codec, qualityLabel);
}
