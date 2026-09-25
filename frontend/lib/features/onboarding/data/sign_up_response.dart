import '../domain/app_user.dart';

/// `POST /users` 응답 (API 계약 5.1)
class SignUpResponse {
  const SignUpResponse({required this.user, required this.accessToken});

  final AppUser user;
  final String accessToken;

  factory SignUpResponse.fromJson(Map<String, dynamic> json) => SignUpResponse(
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
    accessToken: json['accessToken'] as String,
  );
}
