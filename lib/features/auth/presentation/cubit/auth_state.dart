import 'package:equatable/equatable.dart';

import 'package:travel_advisor_mobile/features/auth/domain/entities/login_result.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthSuccess extends AuthState {
  final LoginResult result;
  const AuthSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

class RegisterSuccess extends AuthState {
  const RegisterSuccess();
}

class ForgotPasswordSuccess extends AuthState {
  final String message;
  const ForgotPasswordSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class UpdatePasswordSuccess extends AuthState {
  const UpdatePasswordSuccess();
}

class ChangePasswordSuccess extends AuthState {
  final String message;
  const ChangePasswordSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
