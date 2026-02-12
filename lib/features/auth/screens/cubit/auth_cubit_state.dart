part of 'auth_cubit_cubit.dart';

@immutable
sealed class AuthCubitState {}

final class AuthInitial extends AuthCubitState {}

final class AuthLoading extends AuthCubitState {}

final class AuthSuccess extends AuthCubitState {}

final class AuthError extends AuthCubitState {
  final String message;
  AuthError(this.message);
}
