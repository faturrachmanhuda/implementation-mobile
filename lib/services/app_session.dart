class AppSession {
  static String userName = 'User';
  static String userEmail = '-';
  static String profilePictureUrl = '';
  static String activeProjectId = '';
  static String activeProjectName = '';
  static String activeProjectNotificationFingerprint = '';
  static String activeProjectNotificationMessage = '';
  static final Set<String> seenProjectNotificationFingerprints = {};

  static void clear() {
    userName = 'User';
    userEmail = '-';
    profilePictureUrl = '';
    activeProjectId = '';
    activeProjectName = '';
    activeProjectNotificationFingerprint = '';
    activeProjectNotificationMessage = '';
    seenProjectNotificationFingerprints.clear();
  }
}
