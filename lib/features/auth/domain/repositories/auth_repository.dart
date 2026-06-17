import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';

/// Contract for auth operations.
/// Presentation layer depends ONLY on this interface — never on implementation.
abstract class AuthRepository {
  /// Authenticates a user using email/phone and password.
  /// Returns a [LoginResult] containing the auth tokens.
  Future<LoginResult> login({
    required String emailOrPhone,
    required String password,
  });

  /// Registers a new tourist account.
  Future<void> registerTourist({
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String password,
  });

  /// Initiates the forgot password flow by sending a reset link to the [email].
  /// Returns a status or message string.
  Future<String> forgotPassword(String email);

  /// Updates the password using a reset token.
  Future<void> updatePassword({
    required String accessToken,
    required String newPassword,
  });

  /// Changes the user's password while they are authenticated.
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Authenticates the user via Google OAuth.
  Future<LoginResult> loginWithGoogle();
}
