import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const bool kUseMockData = false; 

  static const bool kSkipLogin = false;

  static String get kMapProvider => 'goong'; 
  
  static String get kGoongMaptilesKey => dotenv.env['GOONG_MAPTILES_KEY'] ?? '';
  
  static String get kGoongApiKey => dotenv.env['GOONG_API_KEY'] ?? '';
  
  static String get kGoogleMapKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  
  static String get kGoongMapStyle {
    final baseUrl = dotenv.env['GOONG_MAP_STYLE'] ?? 'https://tiles.goong.io/assets/goong_map_web.json';
    return '$baseUrl?api_key=$kGoongMaptilesKey';
  }
}
