class AppValidators {
  AppValidators._();

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null
          ? 'El campo $fieldName es obligatorio'
          : 'Este campo es obligatorio';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo electrónico es obligatorio';
    }
    final emailRegex = RegExp(r'^[\w\.\-]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'El correo electrónico no tiene un formato válido';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es obligatoria';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'La contraseña debe incluir al menos una mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'La contraseña debe incluir al menos una minúscula';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'La contraseña debe incluir al menos un número';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`~]').hasMatch(value)) {
      return 'La contraseña debe incluir al menos un símbolo';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return 'Debes confirmar la contraseña';
    }
    if (value != original) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es obligatorio';
    }
    final phoneRegex = RegExp(r'^[0-9+\-\s()]{7,20}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'El teléfono no tiene un formato válido';
    }
    return null;
  }

  static String? scaleAnswer(String? value) {
    if (value == null || value.isEmpty) {
      return 'Debes seleccionar una respuesta';
    }
    final parsed = int.tryParse(value);
    if (parsed == null || parsed < 1 || parsed > 5) {
      return 'La respuesta debe estar entre 1 y 5';
    }
    return null;
  }
}
