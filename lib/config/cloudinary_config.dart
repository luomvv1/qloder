class CloudinaryConfig {
  static const cloudName = 'dvnfpynw5';
  static const uploadPreset = 'imagefood';
  static const folder = 'qloder_foods';

  static bool get isConfigured =>
      cloudName.trim().isNotEmpty &&
      uploadPreset.trim().isNotEmpty &&
      cloudName != 'YOUR_CLOUD_NAME' &&
      uploadPreset != 'YOUR_UNSIGNED_UPLOAD_PRESET';
}