/// Represents the file type of a scanned document result.
///
/// This enum indicates the actual file format of the scanned content
/// returned by the document scanner. The type corresponds to the
/// [DocScanKitFormat] setting used during scanning.
///
/// Example usage:
/// ```dart
/// final results = await docScanKit.scanner();
/// for (final result in results) {
///   switch (result.type) {
///     case DocScanKitResultType.jpeg:
///       print('Image file: ${result.path}');
///       break;
///     case DocScanKitResultType.pdf:
///       print('PDF document: ${result.path}');
///       break;
///   }
/// }
/// ```
enum DocScanKitResultType {
  /// Indicates the result is a JPEG image file.
  ///
  /// This type is returned when:
  /// - [DocScanKitFormat.images] was used during scanning
  /// - Each scanned page is saved as an individual JPEG file
  /// - The file has a .jpeg or .jpg extension
  ///
  /// JPEG files can be displayed directly in image widgets
  /// and processed using standard image manipulation libraries.
  jpeg,

  /// Indicates the result is a PDF document file.
  ///
  /// This type is returned when:
  /// - [DocScanKitFormat.document] was used during scanning
  /// - All scanned pages are combined into a single PDF file
  /// - The file has a .pdf extension
  ///
  /// PDF files can be viewed using PDF viewers, shared as documents,
  /// or processed using PDF manipulation libraries.
  pdf;
}
