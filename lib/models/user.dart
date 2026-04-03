import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String username;
  final String email;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'email_verified')
  final bool? emailVerified;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'deletion_requested')
  final bool? deletionRequested;
  @JsonKey(name: 'deletion_requested_at')
  final String? deletionRequestedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    this.isActive,
    this.emailVerified,
    this.createdAt,
    this.deletionRequested,
    this.deletionRequestedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    }
    return username;
  }
}
