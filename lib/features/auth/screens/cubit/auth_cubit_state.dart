part of 'auth_cubit_cubit.dart';

@immutable
sealed class AuthCubitState {}

final class AuthCubitInitial extends AuthCubitState {}

final class AuthCubitLoading extends AuthCubitState {}

final class AuthCubitSuccess extends AuthCubitState {}

final class AuthCubitError extends AuthCubitState {
  final String message;
  AuthCubitError(this.message);
}
