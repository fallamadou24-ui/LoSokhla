enum UserRole { artisan, particulier, admin }

extension UserRoleParsing on UserRole {
  static UserRole fromString(String value) {
    final normalized = value.toLowerCase();
    switch (normalized) {
      case 'artisan':
        return UserRole.artisan;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.particulier;
    }
  }

  String get nameValue {
    switch (this) {
      case UserRole.artisan:
        return 'artisan';
      case UserRole.admin:
        return 'admin';
      case UserRole.particulier:
        return 'particulier';
    }
  }
}
