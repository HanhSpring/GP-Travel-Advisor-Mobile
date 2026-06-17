import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';

/// Contract for auth operations.
/// Presentation layer depends ONLY on this interface — never on implementation.
abstract class AuthRepository {
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  });

  Future<void> registerTourist({
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String password,
  });

  Future<String> forgotPassword(String email);

  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  });

  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<LoginResult> loginWithGoogle();
}
