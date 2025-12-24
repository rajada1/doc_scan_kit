/// Defines the output format for scanned documents.
///
/// This enum determines how the document scanner processes and returns
/// scanned content. The choice affects both the file format and the
/// number of files returned from a scanning session.
///
/// Example usage:
/// ```dart
/// final options = DocScanKitOptionsAndroid(
///   format: DocScanKitFormat.document, // Creates a single PDF
/// );
///
/// final results = await docScanKit.scanner();
/// // With 'document' format: results contains 1 PDF file
/// // With 'images' format: results contains multiple JPEG files
/// ```
enum DocScanKitFormat {
  /// Returns individual JPEG image files for each scanned page.
  ///
  /// When this format is selected:
  /// - Each scanned page becomes a separate JPEG file
  /// - Multiple files are returned for multi-page documents
  /// - Files are stored in the app's documents directory
  /// - Each file has a unique filename with .jpeg extension
  ///
  /// This format is ideal when you need to:
  /// - Process individual pages separately
  /// - Display pages in a custom gallery interface
  /// - Apply different processing to different pages
  /// - Maintain maximum image quality without PDF compression
  images,

  /// Returns a single PDF document containing all scanned pages.
  ///
  /// When this format is selected:
  /// - All scanned pages are combined into one PDF file
  /// - Only one file is returned regardless of page count
  /// - Each page becomes a separate page within the PDF
  /// - The PDF is stored in the app's documents directory
  ///
  /// This format is ideal when you need to:
  /// - Create a complete document from multiple pages
  /// - Share or store documents in a standard format
  /// - Maintain page order and document structure
  /// - Reduce the number of files to manage
  document;
}
