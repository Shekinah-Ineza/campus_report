/// Cloudinary settings for photo uploads.
///
/// Firebase Storage now requires a paid (Blaze) billing account, so with the
/// lecturer's approval photos are stored on Cloudinary's free plan instead.
/// The photo's URL is then saved in the incident document in Firestore.
class CloudinaryConfig {
  CloudinaryConfig._();

  /// Your Cloudinary "Cloud name" (Cloudinary console → API Keys).
  static const cloudName = 'uirinzzp';

  /// The UNSIGNED upload preset created in Cloudinary settings.
  static const uploadPreset = 'campus_report';
}
