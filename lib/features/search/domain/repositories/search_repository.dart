import '../entities/search_location.dart';

abstract class SearchRepository {
  Future<List<SearchLocation>> getRecentSearches();
}
