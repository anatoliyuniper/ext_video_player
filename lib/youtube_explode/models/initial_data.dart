import 'package:meta/meta.dart';

import 'package:ext_video_player/youtube_explode/extensions/helpers_extension.dart';

abstract class InitialData {
  @protected
  final JsonMap root;

  InitialData(this.root);
}
