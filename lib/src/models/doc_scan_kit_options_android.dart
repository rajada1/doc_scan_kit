import 'package:doc_scan_kit/src/models/doc_scan_kit_options.dart';
import 'package:doc_scan_kit/src/models/scanner_mode_android.dart';

/// Android-specific configuration options for the document scanner.
///
/// This class extends [DocScanKitOptions] to provide Android-specific settings
/// that control the behavior of Google's ML Kit Document Scanner API.
///
/// These options allow fine-tuning of the scanner experience on Android devices,
/// including page limits, scanner modes, and gallery import capabilities.
///
/// Example usage:
/// ```dart
/// final androidOptions = DocScanKitOptionsAndroid(
///   format: DocScanKitFormat.document,
///   pageLimit: 10,
///   scannerMode: ScannerModeAndroid.full,
///   isGalleryImport: true,
/// );
/// ```
class DocScanKitOptionsAndroid extends DocScanKitOptions {
  /// Creates Android-specific scanner options with the given configuration.
  ///
  /// [format] - Output format for scanned documents (inherited from parent).
  /// [pageLimit] - Maximum number of pages that can be scanned in one session.
  /// [scannerMode] - Scanner mode determining available features and capabilities.
  /// [isGalleryImport] - Whether users can import images from the photo gallery.
  const DocScanKitOptionsAndroid({
    super.format,
    this.pageLimit = 1,
    this.scannerMode = ScannerModeAndroid.full,
    this.isGalleryImport = true,
  });

  /// Maximum number of pages that can be scanned in a single scanning session.
  ///
  /// This property limits how many document pages a user can capture before
  /// the scanner automatically completes the session. Setting a higher limit
  /// allows for multi-page document scanning.
  ///
  /// Valid range: 1 to 100 pages
  /// Default value: 1
  ///
  /// Note: The actual limit may be constrained by device memory and performance.
  final int pageLimit;

  /// Scanner mode that determines which features and capabilities are enabled.
  ///
  /// This property controls the level of functionality available in the scanner:
  /// - [ScannerModeAndroid.base]: Basic editing capabilities (crop, rotate, reorder)
  /// - [ScannerModeAndroid.filter]: Adds image filters to base mode
  /// - [ScannerModeAndroid.full]: Adds ML-powered cleaning and future features
  ///
  /// Default value: [ScannerModeAndroid.full]
  ///
  /// Higher modes provide more features but may require more processing power
  /// and potentially longer processing times.
  final ScannerModeAndroid scannerMode;

  /// Whether users can import existing images from the device's photo gallery.
  ///
  /// When enabled, the scanner interface will include an option for users to
  /// select existing photos from their gallery instead of only capturing new ones.
  /// This is useful for processing documents that were previously photographed.
  ///
  /// Default value: true
  ///
  /// Note: Gallery import requires appropriate storage permissions on the device.
  final bool isGalleryImport;

  /// Serializes these Android options to a JSON map for native communication.
  ///
  /// This method converts all Android-specific configuration options into a
  /// map format that can be sent to the native Android implementation through
  /// method channels.
  ///
  /// Returns a [Map<String, dynamic>] containing:
  /// - 'format': The output format as a string name
  /// - 'pageLimit': The maximum number of pages as an integer
  /// - 'scannerMode': The scanner mode as a string name
  /// - 'isGalleryImport': The gallery import setting as a boolean
  @override
  Map<String, dynamic> toJson() => {
        'format': format.name,
        'pageLimit': pageLimit,
        'scannerMode': scannerMode.name,
        'isGalleryImport': isGalleryImport,
      };
}
