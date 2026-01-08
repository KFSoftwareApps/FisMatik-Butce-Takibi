
class FamilyMember {
  final String userId;
  final String email;
  final String role; // 'owner' | 'member' vb.
  final String status; // 'active' | 'pending' | 'rejected'

  const FamilyMember({
    required this.userId,
    required this.email,
    required this.role,
    this.status = 'active',
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'role': role,
      'status': status,
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      userId: map['userId'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'member',
      status: map['status'] ?? 'active',
    );
  }
}

class Family {
  final String id;
  final String ownerUserId;
  final String name;
  final List<FamilyMember> members;

  /// Aileye ait tüm mailler (lower-case). Sorgu için kullanıyoruz.
  final List<String> memberEmails;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const Family({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.members,
    required this.createdAt,
    this.updatedAt,
    this.memberEmails = const [],
  });

  Map<String, dynamic> toMap() {
    // memberEmails boşsa members listesinden derivasyon yap
    final emails = memberEmails.isNotEmpty
        ? memberEmails.map((e) => e.toLowerCase()).toList()
        : members.map((m) => m.email.toLowerCase()).toList();

    return {
      'ownerUserId': ownerUserId,
      'name': name,
      'members': members.map((m) => m.toMap()).toList(),
      'memberEmails': emails,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Family.fromMap(Map<String, dynamic> map) {
    final membersRaw = map['members'] as List<dynamic>? ?? const [];

    final members = membersRaw
        .map((e) => FamilyMember.fromMap(e as Map<String, dynamic>))
        .toList();

    final emailsRaw = map['memberEmails'] as List<dynamic>?;
    final memberEmails = (emailsRaw != null && emailsRaw.isNotEmpty)
        ? emailsRaw.map((e) => (e as String).toLowerCase()).toList()
        : members.map((m) => m.email.toLowerCase()).toList();

    return Family(
      id: map['id'] ?? '',
      ownerUserId: map['ownerUserId'] ?? '',
      name: map['name'] ?? '',
      members: members,
      memberEmails: memberEmails,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDateNullable(map['updatedAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    return DateTime.now();
  }

  static DateTime? _parseDateNullable(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
