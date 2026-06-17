import 'package:travel_advisor_mobile/features/auth/domain/entities/user_entity.dart';

class LoginResult {
  final UserEntity user;
  final String accessToken;
  final String refreshToken;

  const LoginResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });
}
