

class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String phone;

  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.phone,
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
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      email: (map['email'] ?? '') as String,
      firstName: (map['firstName'] ?? '') as String,
      lastName: (map['lastName'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
    );
  }
}
