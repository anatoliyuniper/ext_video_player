import 'package:ext_video_player/youtube_explode/models/fragment.dart';
import 'package:http_parser/http_parser.dart';

import 'bitrate.dart';
import 'filesize.dart';
import 'framerate.dart';
import 'stream_container.dart';
import 'video_quality.dart';
import 'video_resolution.dart';
import 'video_stream_info.dart';

/// YouTube media stream that only contains video.
class VideoOnlyStreamInfo extends VideoStreamInfo {
  VideoOnlyStreamInfo(
      int tag,
      Uri url,
      StreamContainer container,
      FileSize size,
      Bitrate bitrate,
      String videoCodec,
      String videoQualityLabel,
      VideoQuality videoQuality,
      VideoResolution videoResolution,
      Framerate framerate,
      List<Fragment> fragments,
      MediaType codec,
      String qualityLabel)
      : super(
            tag,
            url,
            container,
            size,
            bitrate,
            videoCodec,
            videoQualityLabel,
            videoQuality,
            videoResolution,
            framerate,
            fragments,
            codec,
            qualityLabel);

  @override
  String toString() => 'Video-only ($tag | $videoResolution | $container)';
}
