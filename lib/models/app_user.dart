enum UserRole {
  student,
  staff;

  static UserRole fromValue(String? value) =>
      value == 'staff' ? UserRole.staff : UserRole.student;
}

/// A user profile stored at users/{uid}.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;

  bool get isStaff => role == UserRole.staff;

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) => AppUser(
        uid: uid,
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        role: UserRole.fromValue(data['role'] as String?),
      );
}
