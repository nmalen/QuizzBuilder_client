class UserCredits {
  final int balance;

  const UserCredits({required this.balance});

  factory UserCredits.fromJson(Map<String, dynamic> json) {
    return UserCredits(balance: (json['balance'] as num?)?.toInt() ?? 0);
  }
}
