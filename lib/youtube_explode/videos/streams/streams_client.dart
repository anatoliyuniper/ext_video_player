import 'package:ext_video_player/youtube_explode/cipher/cipher_operations.dart';
import 'package:ext_video_player/youtube_explode/client/embedded_player_client.dart';
import 'package:ext_video_player/youtube_explode/models/stream_info_provider.dart';
import 'package:ext_video_player/youtube_explode/pages/watch_page.dart';
import 'package:ext_video_player/youtube_explode/player/player_source.dart';

import '../../dash_manifest.dart';
import '../../exceptions/exceptions.dart';
import '../../extensions/helpers_extension.dart';
import '../../heuristics.dart';
import '../../youtube_http_client.dart';
import '../video_id.dart';
import 'bitrate.dart';
import 'filesize.dart';
import 'framerate.dart';
import 'stream_container.dart';
import 'stream_context.dart';
import 'stream_info.dart';
import 'stream_manifest.dart';
import 'streams.dart';

/// Queries related to media streams of YouTube videos.
class StreamsClient {
  final YoutubeHttpClient _httpClient;

  /// Initializes an instance of [StreamsClient]
  StreamsClient(this._httpClient);

  Future<DashManifest> _getDashManifest(
      Uri dashManifestUrl, Iterable<CipherOperation> cipherOperations) {
    var signature =
        DashManifest.getSignatureFromUrl(dashManifestUrl.toString());
    if (!signature.isNullOrWhiteSpace) {
      signature = cipherOperations.decipher(signature!);
      dashManifestUrl = dashManifestUrl.setQueryParam('signature', signature);
    }
    return DashManifest.get(_httpClient, dashManifestUrl);
  }

  Future<StreamContext> _getStreamContextFromEmbeddedClient(
      VideoId videoId) async {
    final page = await EmbeddedPlayerClient.get(_httpClient, videoId.value);

    return StreamContext(page.streams.toList(), const []);
  }

  Future<StreamContext> _getStreamContextFromWatchPage(VideoId videoId) async {
    final watchPage = await WatchPage.get(_httpClient, videoId.toString());

    final playerConfig = watchPage.playerConfig;

    var playerResponse =
        watchPage.playerResponse ?? playerConfig?.playerResponse;
    if (playerResponse == null) {
      throw VideoUnplayableException.unplayable(videoId);
    }

    var previewVideoId = playerResponse.previewVideoId;
    if (!previewVideoId.isNullOrWhiteSpace) {
      throw VideoRequiresPurchaseException.preview(
          videoId, VideoId(previewVideoId!));
    }

    var playerSourceUrl = watchPage.sourceUrl ?? playerConfig?.sourceUrl;
    var playerSource = !playerSourceUrl.isNullOrWhiteSpace
        ? await PlayerSource.get(_httpClient, playerSourceUrl!)
        : null;
    var cipherOperations =
        playerSource?.getCipherOperations() ?? const <CipherOperation>[];

    if (!playerResponse.isVideoPlayable) {
      throw VideoUnplayableException.unplayable(videoId,
          reason: playerResponse.videoPlayabilityError ?? '');
    }

    if (playerResponse.isLive) {
      throw VideoUnplayableException.liveStream(videoId);
    }

    var streamInfoProviders = <StreamInfoProvider>[
      ...playerResponse.streams,
    ];

    var dashManifestUrl = playerResponse.dashManifestUrl;
    if (!(dashManifestUrl?.isNullOrWhiteSpace ?? true)) {
      var dashManifest =
          await _getDashManifest(Uri.parse(dashManifestUrl!), cipherOperations);
      streamInfoProviders.addAll(dashManifest.streams);
    }
    return StreamContext(streamInfoProviders, cipherOperations);
  }

  Future<StreamManifest> _getManifest(StreamContext streamContext) async {
    // To make sure there are no duplicates streams, group them by tag
    var streams = <int, StreamInfo>{};

    for (final streamInfo in streamContext.streamInfoProviders) {
      var tag = streamInfo.tag;
      var url = Uri.parse(streamInfo.url);

      // Signature
      var signature = streamInfo.signature;
      var signatureParameter = streamInfo.signatureParameter ?? 'signature';

      if (!signature.isNullOrWhiteSpace) {
        signature = streamContext.cipherOperations.decipher(signature!);
        url = url.setQueryParam(signatureParameter, signature);
      }

      // Content length - Dont try to get content length of a dash stream.
      var contentLength = streamInfo.source == StreamSource.dash
          ? 0
          : streamInfo.contentLength ??
              await _httpClient.getContentLength(url, validate: false) ??
              0;

      if (contentLength == 0 && streamInfo.source != StreamSource.dash) {
        continue;
      }
      // Common
      var container = StreamContainer.parse(streamInfo.container!);
      var fileSize = FileSize(contentLength);
      var bitrate = Bitrate(streamInfo.bitrate ?? 0);

      var audioCodec = streamInfo.audioCodec;
      var videoCodec = streamInfo.videoCodec;

      // Muxed or Video-only
      if (!videoCodec.isNullOrWhiteSpace) {
        var framerate = Framerate(streamInfo.framerate ?? 24);
        var videoQualityLabel = streamInfo.qualityLabel;

        var videoQuality = VideoQualityUtil.fromLabel(videoQualityLabel);

        var videoWidth = streamInfo.videoWidth;
        var videoHeight = streamInfo.videoHeight;
        var videoResolution = videoWidth != -1 && videoHeight != -1
            ? VideoResolution(videoWidth ?? 0, videoHeight ?? 0)
            : videoQuality.toVideoResolution();

        // Muxed
        if (!audioCodec.isNullOrWhiteSpace &&
            streamInfo.source != StreamSource.adaptive) {
          streams[tag] = MuxedStreamInfo(
              tag,
              url,
              container,
              fileSize,
              bitrate,
              audioCodec!,
              videoCodec!,
              videoQualityLabel,
              videoQuality,
              videoResolution,
              framerate,
              streamInfo.codec,
              streamInfo.qualityLabel);
          continue;
        }

        // Video only
        streams[tag] = VideoOnlyStreamInfo(
            tag,
            url,
            container,
            fileSize,
            bitrate,
            videoCodec!,
            videoQualityLabel,
            videoQuality,
            videoResolution,
            framerate,
            streamInfo.fragments ?? const [],
            streamInfo.codec,
            streamInfo.qualityLabel);
        continue;
      }
      // Audio-only
      if (!audioCodec.isNullOrWhiteSpace) {
        streams[tag] = AudioOnlyStreamInfo(
            tag,
            url,
            container,
            fileSize,
            bitrate,
            audioCodec!,
            streamInfo.fragments ?? const [],
            streamInfo.codec,
            streamInfo.qualityLabel);
      }

      // #if DEBUG
      // throw FatalFailureException("Stream info doesn't contain audio/video codec information.");
    }

    return StreamManifest(streams.values);
  }

  /// Gets the manifest that contains information
  /// about available streams in the specified video.
  Future<StreamManifest> getManifest(dynamic videoId) async {
    videoId = VideoId.fromString(videoId);

    try {
      final context = await _getStreamContextFromEmbeddedClient(videoId);
      return _getManifest(context);
    } on YoutubeExplodeException {
      //TODO: ignore
    }
    final context = await _getStreamContextFromWatchPage(videoId);
    return _getManifest(context);
  }

  /// Gets the HTTP Live Stream (HLS) manifest URL
  /// for the specified video (if it's a live video stream).
  Future<String> getHttpLiveStreamUrl(VideoId videoId) async {
    final watchPage = await WatchPage.get(_httpClient, videoId.value);

    final playerResponse = watchPage.playerResponse;

    if (playerResponse == null) {
      throw TransientFailureException(
          'Couldn\'t extract the playerResponse from the Watch Page!');
    }

    if (!playerResponse.isVideoPlayable) {
      throw VideoUnplayableException.unplayable(videoId,
          reason: playerResponse.videoPlayabilityError ?? '');
    }

    var hlsManifest = playerResponse.hlsManifestUrl;
    if (hlsManifest == null) {
      throw VideoUnplayableException.notLiveStream(videoId);
    }
    return hlsManifest;
  }

  /// Gets the actual stream which is identified by the specified metadata.
  Stream<List<int>> get(StreamInfo streamInfo) =>
      _httpClient.getStream(streamInfo);
}
