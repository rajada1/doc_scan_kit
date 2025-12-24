import 'package:doc_scan_kit/src/models/doc_scan_kit_format.dart';

/// Abstract base class for platform-specific document scanner configuration options.
///
/// This class defines the common interface and shared properties for configuring
/// the document scanner behavior across different platforms. Platform-specific
/// implementations should extend this class and provide their own additional options.
///
/// The main shared property is [format], which determines whether the scanner
/// should return individual image files or a combined PDF document.
abstract class DocScanKitOptions {
  /// Creates a new [DocScanKitOptions] instance with the specified format.
  ///
  /// [format] - Determines the output format of scanned documents.
  /// Defaults to [DocScanKitFormat.images] if not specified.
  const DocScanKitOptions({this.format = DocScanKitFormat.images});

  /// The output format for scanned documents.
  ///
  /// This property controls how the scanner processes and returns scanned content:
  /// - [DocScanKitFormat.images]: Returns individual JPEG image files for each scanned page
  /// - [DocScanKitFormat.document]: Returns a single PDF file containing all scanned pages
  ///
  /// The default value is [DocScanKitFormat.images].
  final DocScanKitFormat format;

  /// Converts this options object to a JSON map for platform communication.
  ///
  /// Platform-specific implementations must override this method to serialize
  /// their configuration options into a format that can be sent to native code
  /// through method channels.
  ///
  /// Returns a [Map<String, dynamic>] containing the serialized options.
  Map<String, dynamic> toJson();
}
