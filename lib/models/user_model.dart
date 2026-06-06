class UserModel {
  final int? id;
  final String name;
  final String email;
  final String password;
  final String? supabaseId;
  final DateTime createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.password,
    this.supabaseId,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? supabaseId,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      supabaseId: supabaseId ?? this.supabaseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'supabase_id': supabaseId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      supabaseId: map['supabase_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
