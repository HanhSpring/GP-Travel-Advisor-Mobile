import '../models/destination_model.dart';
import '../models/hotel_model.dart';
import '../models/trip_suggestion_model.dart';

/// Contract for home screen data.
abstract class HomeDataSource {
  Future<List<TripSuggestionModel>> getSuggestions();
  Future<List<DestinationModel>> getDestinations();
  Future<List<HotelModel>> getHotels();
}

// ─────────────────────────────────────────────────────────────────────────────
/// Mock — simulates API with picsum.photos image URLs.
// ─────────────────────────────────────────────────────────────────────────────
class MockHomeDataSource implements HomeDataSource {
  @override
  Future<List<TripSuggestionModel>> getSuggestions() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return const [
      TripSuggestionModel(id: 'trip-001', title: 'Kỳ nghỉ Phú Quốc', days: '3 ngày', location: 'Kiên Giang', views: '2.4k', likes: '512', imageUrl: 'https://images.unsplash.com/photo-1550608682-1a415d862f1c?w=600&q=80', placeholderColor: 0xFF4A90D9),
      TripSuggestionModel(id: 'trip-002', title: 'Du lịch Hà Nội', days: '4 ngày', location: 'Hà Nội', views: '1.8k', likes: '324', imageUrl: 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=600&q=80', placeholderColor: 0xFF6C9E5C),
      TripSuggestionModel(id: 'trip-003', title: 'Kỳ nghỉ Quy Nhơn', days: '5 ngày', location: 'Bình Định', views: '892', likes: '201', imageUrl: 'https://images.unsplash.com/photo-1583483425010-c566a31bc9f8?w=600&q=80', placeholderColor: 0xFF5E7FA0),
      TripSuggestionModel(id: 'trip-004', title: 'Khám phá Đà Lạt', days: '3 ngày', location: 'Lâm Đồng', views: '1.1k', likes: '287', imageUrl: 'https://images.unsplash.com/photo-1596401037688-69cb907abf12?w=600&q=80', placeholderColor: 0xFF7D5E92),
    ];
  }

  @override
  Future<List<DestinationModel>> getDestinations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return const [
      DestinationModel(id: 'dest-001', name: 'Sapa', imageUrl: 'https://images.unsplash.com/photo-1549488344-1f9b8d2bd1f3?w=300&q=80', placeholderColor: 0xFF4A8C5C),
      DestinationModel(id: 'dest-002', name: 'Hội An', imageUrl: 'https://images.unsplash.com/photo-1559592413-73138379c13b?w=300&q=80', placeholderColor: 0xFF8B7355),
      DestinationModel(id: 'dest-003', name: 'Đà Lạt', imageUrl: 'https://images.unsplash.com/photo-1622306911579-2afb847fe8f8?w=300&q=80', placeholderColor: 0xFF3D7A5E),
      DestinationModel(id: 'dest-004', name: 'Hạ Long', imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=300&q=80', placeholderColor: 0xFF2E6B8A),
      DestinationModel(id: 'dest-005', name: 'Đà Nẵng', imageUrl: 'https://images.unsplash.com/photo-1559506825-f933e38714eb?w=300&q=80', placeholderColor: 0xFF1565C0),
    ];
  }

  @override
  Future<List<HotelModel>> getHotels() async {
    await Future.delayed(const Duration(milliseconds: 350));
    return const [
      HotelModel(id: 'hotel-001', name: 'Inter Phu Quoc', rating: 4.9, price: '2.500.000đ', imageUrl: 'https://images.unsplash.com/photo-1561501878-aabd62634533?w=400&q=80', placeholderColor: 0xFFD4C5B0),
      HotelModel(id: 'hotel-002', name: 'JW Marriott', rating: 4.8, price: '3.200.000đ', imageUrl: 'https://images.unsplash.com/photo-1542314831-c6a420325142?w=400&q=80', placeholderColor: 0xFF8DACC4),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Remote placeholder — activate when backend is ready.
// ─────────────────────────────────────────────────────────────────────────────
// class RemoteHomeDataSource implements HomeDataSource {
//   final DioClient _client;
//   RemoteHomeDataSource(this._client);
//
//   @override
//   Future<List<TripSuggestionModel>> getSuggestions() async {
//     final res = await _client.dio.get('/home/suggestions');
//     return (res.data as List).map((e) => TripSuggestionModel.fromJson(e)).toList();
//   }
//   ...
// }
