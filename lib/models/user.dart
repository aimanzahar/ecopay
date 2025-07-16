class User {
  final int? id;
  final String name;
  final bool ecopayOptIn;

  User({
    this.id,
    required this.name,
    this.ecopayOptIn = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ecopay_opt_in': ecopayOptIn ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      ecopayOptIn: map['ecopay_opt_in'] == 1,
    );
  }
}