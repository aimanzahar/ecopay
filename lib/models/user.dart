class User {
  final int? id;
  final String name;
  final String username;
  final String email;
  final bool ecopayOptIn;
  final int totalPoints;
  final int level;
  final String? badgesEarned;
  final DateTime? createdAt;
  final DateTime? lastActive;

  User({
    this.id,
    required this.name,
    required this.username,
    required this.email,
    this.ecopayOptIn = false,
    this.totalPoints = 0,
    this.level = 1,
    this.badgesEarned,
    this.createdAt,
    this.lastActive,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'ecopay_opt_in': ecopayOptIn ? 1 : 0,
      'total_points': totalPoints,
      'level': level,
      'badges_earned': badgesEarned ?? '',
      'created_at': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'last_active': lastActive?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      ecopayOptIn: map['ecopay_opt_in'] == 1,
      totalPoints: map['total_points'] ?? 0,
      level: map['level'] ?? 1,
      badgesEarned: map['badges_earned'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      lastActive: map['last_active'] != null ? DateTime.parse(map['last_active']) : null,
    );
  }

  // Helper method to get badges as a list
  List<String> get badgesList {
    if (badgesEarned == null || badgesEarned!.isEmpty) return [];
    return badgesEarned!.split(',').where((badge) => badge.isNotEmpty).toList();
  }

  // Helper method to check if user has a specific badge
  bool hasBadge(String badgeId) {
    return badgesList.contains(badgeId);
  }

  // Copy method for immutable updates
  User copyWith({
    int? id,
    String? name,
    String? username,
    String? email,
    bool? ecopayOptIn,
    int? totalPoints,
    int? level,
    String? badgesEarned,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email ?? this.email,
      ecopayOptIn: ecopayOptIn ?? this.ecopayOptIn,
      totalPoints: totalPoints ?? this.totalPoints,
      level: level ?? this.level,
      badgesEarned: badgesEarned ?? this.badgesEarned,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}