bool isValidEmail(String? email) {
  if (email == null) return false;
  final e = email.trim();
  final regex = RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$");
  return regex.hasMatch(e);
}

bool isValidPassword(String? password, {int minLen = 6}) {
  if (password == null) return false;
  return password.trim().length >= minLen;
}

bool isNonEmpty(String? s) => s != null && s.trim().isNotEmpty;
