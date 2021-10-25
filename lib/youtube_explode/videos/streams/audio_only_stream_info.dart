import 'package:ext_video_player/youtube_explode/models/fragment.dart';
import 'package:http_parser/http_parser.dart';

import 'streams.dart';

/// YouTube media stream that only contains audio.
class AudioOnlyStreamInfo extends AudioStreamInfo {
  AudioOnlyStreamInfo(
      int tag,
      Uri url,
      StreamContainer container,
      FileSize size,
      Bitrate bitrate,
      String audioCodec,
      List<Fragment> fragments,
      MediaType codec,
      String qualityLabel)
      : super(tag, url, container, size, bitrate, audioCodec, fragments, codec,
            qualityLabel);

  @override
  String toString() => 'Audio-only ($tag | $container)';
}
