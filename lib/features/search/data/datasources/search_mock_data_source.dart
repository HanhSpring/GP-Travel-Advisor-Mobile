import '../models/search_location_model.dart';

abstract class SearchMockDataSource {
  Future<List<SearchLocationModel>> getRecentSearches();
}

class SearchMockDataSourceImpl implements SearchMockDataSource {
  @override
  Future<List<SearchLocationModel>> getRecentSearches() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Return mock data matching Figma exactly
    return [
      const SearchLocationModel(
        id: '1',
        name: 'Thủ đô Hà Nội',
        imageUrl: 'https://nhn.1cdn.vn/2025/01/14/1657cnru.png',
      ),
      const SearchLocationModel(
        id: '2',
        name: 'Vịnh Hạ Long',
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=500&q=80',
      ),
      const SearchLocationModel(
        id: '3',
        name: 'Nhà thờ Đức Bà',
        imageUrl: 'https://cdn.xanhsm.com/2024/11/f5d8fc3e-nha-tho-duc-ba-thumbnail-min-1.jpg',
      ),
      const SearchLocationModel(
        id: '4',
        name: 'TP. Hồ Chí Minh',
        imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=500&q=80',
      ),
    ];
  }
}
