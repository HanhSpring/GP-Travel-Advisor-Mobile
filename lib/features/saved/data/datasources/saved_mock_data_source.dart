import '../../../city_detail/domain/entities/city_entities.dart';
import '../../../home/domain/entities/destination.dart';

class SavedMockDataSource {
  Future<List<CityItinerary>> getFavoriteItineraries() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      const CityItinerary(
        id: '1',
        title: 'Kỳ nghỉ Quy Nhơn',
        authorName: 'Hanh Spring',
        authorAvatar: 'https://i.pravatar.cc/150?u=hanh',
        imageUrl: 'https://images.unsplash.com/photo-1570737197266-4d7c380fb305?q=80&w=1000&auto=format&fit=crop',
        duration: '4 ngày',
        views: '1.2k',
        likes: '248',
      ),
      const CityItinerary(
        id: '2',
        title: 'Khám phá Đà Lạt mộng mơ',
        authorName: 'Admin',
        authorAvatar: 'https://i.pravatar.cc/150?u=admin',
        imageUrl: 'https://images.unsplash.com/photo-1589308454674-9f448c967664?q=80&w=1000&auto=format&fit=crop',
        duration: '3 ngày',
        views: '850',
        likes: '156',
      ),
    ];
  }

  Future<List<Destination>> getFavoritePlaces() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      const Destination(
        id: '1',
        name: 'Hạ Long',
        imageUrl: 'https://images.unsplash.com/photo-1528127269322-539801943592?q=80&w=1000&auto=format&fit=crop',
        placeholderColor: 0xFFE3F2FD,
      ),
      const Destination(
        id: '2',
        name: 'Hội An',
        imageUrl: 'https://images.unsplash.com/photo-1555505011-15328490a02a?q=80&w=1000&auto=format&fit=crop',
        placeholderColor: 0xFFFFF3E0,
      ),
      const Destination(
        id: '3',
        name: 'Phú Quốc',
        imageUrl: 'https://images.unsplash.com/photo-1589308050143-6d0e806c986c?q=80&w=1000&auto=format&fit=crop',
        placeholderColor: 0xFFE8F5E9,
      ),
      const Destination(
        id: '4',
        name: 'Nha Trang',
        imageUrl: 'https://images.unsplash.com/photo-1596422846543-b5c641630b91?q=80&w=1000&auto=format&fit=crop',
        placeholderColor: 0xFFF3E5F5,
      ),
    ];
  }
}
