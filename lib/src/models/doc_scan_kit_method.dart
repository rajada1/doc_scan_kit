/// Enumeration of available DocScanKit method calls for platform communication.
/// 
/// This enum defines all the method calls that can be made to the native
/// platform implementations through method channels. Each enum value
/// corresponds to a specific functionality provided by the plugin.
/// 
/// The enum provides a type-safe way to reference method names and
/// automatically generates the correct platform method names using
/// the 'scanKit#' prefix convention.
/// 
/// Example usage:
/// ```dart
/// final methodName = DocScanKitMethod.startDocumentScanner.platformName;
/// // Returns: 'scanKit#startDocumentScanner'
/// ```
enum DocScanKitMethod {
  /// Initiates the native document scanner interface.
  /// 
  /// This method launches the platform-specific document scanner:
  /// - Android: Google ML Kit Document Scanner
  /// - iOS: Apple VNDocumentCameraViewController
  /// 
  /// The scanner allows users to capture one or more document pages
  /// with automatic edge detection and image enhancement.
  startDocumentScanner,

  /// Closes the document scanner and releases associated resources.
  /// 
  /// This method properly disposes of scanner resources and cleans up:
  /// - Active scanner sessions
  /// - ML Kit resources (Android)
  /// - Temporary files and memory allocations
  /// 
  /// Important for preventing memory leaks, especially on Android.
  closeDocumentScanner,

  /// Performs Optical Character Recognition (OCR) on image data.
  /// 
  /// This method processes image bytes to extract readable text using:
  /// - Android: Google ML Kit Text Recognition API
  /// - iOS: Apple Vision Text Recognition framework
  /// 
  /// Returns the recognized text as a string or empty string if no text found.
  recognizeText,

  /// Scans and decodes QR codes from image data.
  /// 
  /// This method analyzes image bytes to detect and decode QR codes using:
  /// - Android: Google ML Kit Barcode Scanning API
  /// - iOS: Apple Vision Barcode Detection framework
  /// 
  /// Returns the decoded QR code content or empty string if no QR code found.
  scanQrCode;

  /// Generates the platform-specific method name for native communication.
  /// 
  /// This getter converts the enum value to the method name format expected
  /// by the native platform implementations. All method names follow the
  /// 'scanKit#methodName' convention.
  /// 
  /// Returns a [String] in the format 'scanKit#enumName' for use in
  /// method channel communication.
  /// 
  /// Example:
  /// ```dart
  /// DocScanKitMethod.startDocumentScanner.platformName
  /// // Returns: 'scanKit#startDocumentScanner'
  /// ```
  String get platformName => 'scanKit#$name';
}
