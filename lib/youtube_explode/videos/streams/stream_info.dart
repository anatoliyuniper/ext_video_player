import 'package:ext_video_player/youtube_explode/models/fragment.dart';
import 'package:http_parser/http_parser.dart';

import 'bitrate.dart';
import 'filesize.dart';
import 'stream_container.dart';
import 'video_stream_info.dart';

/// Generic YouTube media stream.
abstract class StreamInfo {
  /// Stream tag.
  /// Uniquely identifies a stream inside a manifest.
  final int tag;

  /// Stream URL.
  final Uri url;

  /// Stream container.
  final StreamContainer container;

  /// Stream size.
  final FileSize size;

  /// Stream bitrate.
  final Bitrate bitrate;

  /// DASH streams contain multiple stream fragments.
  final List<Fragment> fragments;

  /// Streams codec.
  final MediaType codec;

  /// Stream quality label.
  final String qualityLabel;

  /// Initialize an instance of [StreamInfo].
  StreamInfo(this.tag, this.url, this.container, this.size, this.bitrate,
      this.fragments, this.codec, this.qualityLabel);
}

/// Extension for Iterables of StreamInfo.
extension StreamInfoIterableExt<T extends StreamInfo> on Iterable<T> {
  /// Gets the stream with highest bitrate.
  T withHighestBitrate() => sortByBitrate().last;

  /// Gets the video streams sorted by bitrate in ascending order.
  /// This returns new list without editing the original list.
  List<T> sortByBitrate() =>
      toList()..sort((a, b) => a.bitrate.compareTo(b.bitrate));

  /// Print a formatted text of all the streams. Like youtube-dl -F option.
  String describe() {
    final column = _Column(['format code', 'extension', 'resolution', 'note']);
    for (final e in this) {
      column.write([
        e.tag,
        e.container.name,
        if (e is VideoStreamInfo) e.videoResolution else 'audio only',
        e.qualityLabel,
        e.bitrate,
        e.codec.parameters['codecs'],
        if (e is VideoStreamInfo) e.framerate,
        if (e is VideoStreamInfo) 'video only',
        e.size
      ]);
    }
    return column.toString();
  }
}

/// Utility for [StreamInfoIterableExt.describe]
class _Column {
  final List<String> header;
  final List<List<String>> _values = [];

  _Column(this.header);

  void write(List<Object?> value) => _values
      .add(value.where((e) => e != null).map((e) => e.toString()).toList());

  @override
  String toString() {
    final headerLen = <int>[];
    final buffer = StringBuffer();
    for (final e in header) {
      headerLen.add(e.length + 2);
      buffer.write('$e  ');
    }
    buffer.writeln();

    for (final valueList in _values) {
      for (var i = 0; i < valueList.length; i++) {
        final v = valueList[i];
        if (headerLen.length <= i) {
          buffer.write(', $v');
          continue;
        }
        buffer.write(v.padRight(headerLen[i]));
      }
      buffer.writeln();
    }
    return buffer.toString();
  }
}
