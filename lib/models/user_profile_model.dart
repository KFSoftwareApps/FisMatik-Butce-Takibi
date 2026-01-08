

class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;
  final String? city;
  final String? district;
  final String currency;

  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
    this.city,
    this.district,
    this.currency = 'TRY',
  });

  String get fullName {
    final parts = [firstName.trim(), lastName.trim()]
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.isEmpty ? '' : parts.join(' ');
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'city': city,
      'district': district,
      'currency': currency,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      email: (map['email'] ?? '') as String,
      firstName: (map['firstName'] ?? '') as String,
      lastName: (map['lastName'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      city: map['city'] as String?,
      district: map['district'] as String?,
      currency: map['currency'] as String? ?? 'TRY',
    );
  }
}
