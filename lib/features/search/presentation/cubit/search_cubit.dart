import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_recent_searches.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final GetRecentSearches _getRecentSearches;

  SearchCubit(this._getRecentSearches) : super(const SearchState.initial());

  Future<void> loadRecentSearches() async {
    emit(const SearchState.loading());
    try {
      final recentSearches = await _getRecentSearches();
      emit(SearchState.loaded(recentSearches));
    } catch (e) {
      emit(SearchState.error('Failed to load recent searches'));
    }
  }
}
