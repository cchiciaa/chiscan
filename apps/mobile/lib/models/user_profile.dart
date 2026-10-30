class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.bankName,
    required this.accountNumber,
  });

  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String bankName;
  final String accountNumber;

  static const defaultProfile = UserProfile(
    id: 'user-default-1',
    name: 'Nadia Pratama',
    email: 'nadia@chiscan.app',
    phoneNumber: '081234567890',
    bankName: 'BCA',
    accountNumber: '8830123456',
  );

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? bankName,
    String? accountNumber,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'bankName': bankName,
      'accountNumber': accountNumber,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String ||
        json['name'] is! String ||
        json['email'] is! String ||
        json['phoneNumber'] is! String) {
      throw const FormatException('Data JSON UserProfile tidak valid atau field wajib hilang.');
    }
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      bankName: (json['bankName'] as String?) ?? 'BCA',
      accountNumber: (json['accountNumber'] as String?) ?? '',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          phoneNumber == other.phoneNumber &&
          bankName == other.bankName &&
          accountNumber == other.accountNumber;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      email.hashCode ^
      phoneNumber.hashCode ^
      bankName.hashCode ^
      accountNumber.hashCode;
}
