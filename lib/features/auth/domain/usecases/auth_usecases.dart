import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';
import 'package:travel_advisor_mobile/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<LoginResult> call({
    required String emailOrPhone,
    required String password,
  }) {
    return _repository.login(emailOrPhone: emailOrPhone, password: password);
  }
}

class RegisterTouristUseCase {
  final AuthRepository _repository;
  RegisterTouristUseCase(this._repository);

  Future<void> call({
    required String fullName,
    required String gender,
    required String email,
    required String phoneNumber,
    required String password,
  }) {
    return _repository.registerTourist(
      fullName: fullName,
      gender: gender,
      email: email,
      phoneNumber: phoneNumber,
      password: password,
    );
  }
}

class ForgotPasswordUseCase {
  final AuthRepository _repository;
  ForgotPasswordUseCase(this._repository);

  Future<String> call(String email) {
    return _repository.forgotPassword(email);
  }
}

class UpdatePasswordUseCase {
  final AuthRepository _repository;
  UpdatePasswordUseCase(this._repository);

  Future<void> call({
    required String accessToken,
    required String newPassword,
  }) {
    return _repository.updatePassword(
      accessToken: accessToken,
      newPassword: newPassword,
    );
  }
}

class ChangePasswordUseCase {
  final AuthRepository _repository;
  ChangePasswordUseCase(this._repository);

  Future<String> call({
    required String currentPassword,
    required String newPassword,
  }) {
    return _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}

class LoginWithGoogleUseCase {
  final AuthRepository repository;
  LoginWithGoogleUseCase(this.repository);

  Future<LoginResult> call() async {
    return await repository.loginWithGoogle();
  }
}
