/// Android scanner modes that determine available features and capabilities.
///
/// This enum defines the different levels of functionality available in
/// Google's ML Kit Document Scanner on Android devices. Each mode builds
/// upon the previous one, adding more advanced features and capabilities.
///
/// The choice of scanner mode affects:
/// - Available editing and enhancement features
/// - Processing time and resource usage
/// - Future feature compatibility
/// - User interface options
///
/// Example usage:
/// ```dart
/// final androidOptions = DocScanKitOptionsAndroid(
///   scannerMode: ScannerModeAndroid.full, // Maximum features
/// );
/// ```
enum ScannerModeAndroid {
  /// Basic document scanning with essential editing capabilities.
  ///
  /// This mode provides fundamental document scanning features:
  /// - Document detection and cropping
  /// - Manual crop adjustment
  /// - Page rotation (90-degree increments)
  /// - Page reordering for multi-page documents
  /// - Basic image quality adjustments
  ///
  /// Use this mode when you need:
  /// - Minimal processing overhead
  /// - Fast scanning performance
  /// - Basic document capture without advanced features
  /// - Compatibility with older or lower-end devices
  base,

  /// Enhanced scanning with image filters and automatic improvements.
  ///
  /// This mode includes all [base] features plus:
  /// - Grayscale conversion options
  /// - Automatic image enhancement algorithms
  /// - Contrast and brightness optimization
  /// - Shadow removal and lighting correction
  /// - Color adjustment and saturation controls
  ///
  /// Use this mode when you need:
  /// - Better image quality for scanned documents
  /// - Automatic enhancement of poor lighting conditions
  /// - Professional-looking document output
  /// - Balance between features and performance
  filter,

  /// Full-featured scanning with ML-powered cleaning and future updates.
  ///
  /// This mode includes all [filter] features plus:
  /// - ML-enabled stain and mark removal
  /// - Automatic finger and hand detection/removal
  /// - Advanced noise reduction algorithms
  /// - Smart content enhancement
  /// - Automatic future feature additions via Google Play Services
  ///
  /// Use this mode when you need:
  /// - Maximum document quality and cleanliness
  /// - Advanced ML-powered image processing
  /// - Automatic access to new features as they're released
  /// - Best possible scanning results regardless of source quality
  ///
  /// Note: This mode requires more processing power and may take longer
  /// to process documents, especially on older devices.
  full;
}
