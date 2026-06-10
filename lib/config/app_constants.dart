class AppConstants {
  static const appName = 'SecureShare';
  static const storageBucket = 'secure-files';
  static const publicWebBaseUrl = String.fromEnvironment(
    'APP_WEB_BASE_URL',
    defaultValue: String.fromEnvironment(
      'NEXT_PUBLIC_APP_URL',
      defaultValue: '',
    ),
  );
  static const maxUploadBytes = 50 * 1024 * 1024;
  static const allowedExtensions = {
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'jpg',
    'jpeg',
    'png',
    'zip',
    'rar',
    'txt',
  };
}
