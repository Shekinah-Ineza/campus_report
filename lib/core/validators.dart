/// Form validators. The length limits mirror firestore.rules so the client
/// and the server reject the same input.
class Validators {
  Validators._();

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your name';
    if (v.length < 2) return 'Name must be at least 2 characters';
    if (v.length > 60) return 'Name must be at most 60 characters';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  static String? title(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Add a short title';
    if (v.length < 5) return 'Title must be at least 5 characters';
    if (v.length > 100) return 'Title must be at most 100 characters';
    return null;
  }

  static String? location(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Say where the problem is';
    if (v.length < 2) return 'Location must be at least 2 characters';
    if (v.length > 100) return 'Location must be at most 100 characters';
    return null;
  }

  static String? description(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Describe the problem';
    if (v.length < 10) return 'Description must be at least 10 characters';
    if (v.length > 1000) return 'Description must be at most 1000 characters';
    return null;
  }
}
