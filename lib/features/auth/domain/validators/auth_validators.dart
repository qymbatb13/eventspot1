/// Form validation rules. Pure Dart: used by the forms and the use cases,
/// and trivially testable.
class AuthValidators {
  const AuthValidators._();

  static const int minPasswordLength = 6;
  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите имя';
    if (v.length < 2) return 'Имя слишком короткое';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите email';
    if (!_emailRegExp.hasMatch(v)) return 'Некорректный email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Введите пароль';
    if (v.length < minPasswordLength) {
      return 'Минимум $minPasswordLength символов';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Повторите пароль';
    if (value != original) return 'Пароли не совпадают';
    return null;
  }
}
