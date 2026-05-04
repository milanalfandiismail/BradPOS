part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
  });

  @override
  List<Object> get props => [email, password, fullName];
}

class GoogleSignInRequested extends AuthEvent {}

class ContinueAsGuestRequested extends AuthEvent {}

class SignInAsKaryawanRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInAsKaryawanRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

class SignOutRequested extends AuthEvent {}

class CheckAuthStatus extends AuthEvent {}

class AuthStatusChanged extends AuthEvent {
  final UserEntity? user;
  const AuthStatusChanged(this.user);

  @override
  List<Object> get props => [user ?? 'null'];
}

class UpdateProfileEvent extends AuthEvent {
  final String? shopName;
  final String? remoteImage;
  final String? localImage;
  final String? address;
  final String? phone;

  const UpdateProfileEvent({
    this.shopName,
    this.remoteImage,
    this.localImage,
    this.address,
    this.phone,
  });

  @override
  List<Object> get props => [
        shopName ?? '',
        remoteImage ?? '',
        localImage ?? '',
        address ?? '',
        phone ?? '',
      ];
}
