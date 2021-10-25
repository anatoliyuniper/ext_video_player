
import 'package:ext_video_player/youtube_explode/cipher/cipher_operations.dart';
import 'package:ext_video_player/youtube_explode/models/stream_info_provider.dart';

///
class StreamContext {
  ///
  final Iterable<StreamInfoProvider> streamInfoProviders;

  ///
  final Iterable<CipherOperation> cipherOperations;

  ///
  StreamContext(this.streamInfoProviders, this.cipherOperations);
}
