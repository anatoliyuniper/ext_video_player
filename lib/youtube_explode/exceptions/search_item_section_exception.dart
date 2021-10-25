//

import 'youtube_explode_exception.dart';

/// Exception thrown when the Item Section is missing from a search request.
class SearchItemSectionException extends YoutubeExplodeException {
  SearchItemSectionException() : super('Failed to find the item section.');
}
