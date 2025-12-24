import 'dart:io';

import 'package:doc_scan_kit/src/doc_scan_kit_platform.dart';
import 'package:doc_scan_kit/src/models/doc_scan_kit_options.dart';
import 'package:doc_scan_kit/src/models/doc_scan_kit_options_android.dart';
import 'package:doc_scan_kit/src/models/doc_scan_kit_options_ios.dart';
import 'package:doc_scan_kit/src/models/doc_scan_kit_result.dart';

/// DocScanKit is the main class that provides a platform-agnostic interface for
/// scanning documents, recognizing text, and scanning QR codes.
///
/// This class automatically handles platform-specific implementations and
/// provides a unified API for both Android and iOS platforms.
///
/// Example usage:
/// ```dart
/// final docScanKit = DocScanKit(
///   androidOptions: DocScanKitOptionsAndroid(
///     pageLimit: 5,
///     scannerMode: ScannerModeAndroid.full,
///   ),
///   iosOptions: DocScanKitOptionsIOS(
///     compressionQuality: 0.8,
///     modalPresentationStyle: ModalPresentationStyleIOS.overFullScreen,
///   ),
/// );
///
/// final results = await docScanKit.scanner();
/// ```
class DocScanKit {
  /// Creates a new instance of [DocScanKit] with platform-specific options.
  ///
  /// [androidOptions] - Configuration options for Android platform.
  /// Defaults to [DocScanKitOptionsAndroid()] if not specified.
  /// [iosOptions] - Configuration options for iOS platform.
  /// Defaults to [DocScanKitOptionsIOS()] if not specified.
  ///
  /// The provided options serve as defaults but can be overridden
  /// on a per-call basis in the [scanner] method.
  const DocScanKit({
    this.androidOptions = const DocScanKitOptionsAndroid(),
    this.iosOptions = const DocScanKitOptionsIOS(),
  });

  /// Default platform-specific options for Android devices.
  ///
  /// These options control Android-specific behavior such as page limits,
  /// scanner modes, and gallery import capabilities.
  ///
  /// These serve as default values that can be overridden in individual
  /// [scanner] method calls.
  final DocScanKitOptionsAndroid androidOptions;

  /// Default platform-specific options for iOS devices.
  ///
  /// These options control iOS-specific behavior such as modal presentation style,
  /// image compression quality, and UI tint colors.
  ///
  /// These serve as default values that can be overridden in individual
  /// [scanner] method calls.
  final DocScanKitOptionsIOS iosOptions;

  /// Launches the native document scanner interface and returns scanned results.
  ///
  /// This method opens the platform-specific document scanner (Camera on iOS,
  /// ML Kit Document Scanner on Android) and allows users to scan one or more
  /// document pages.
  ///
  /// [androidOptions] - Optional Android-specific options for this scan session.
  /// If not provided, uses the instance's default [androidOptions].
  /// [iosOptions] - Optional iOS-specific options for this scan session.
  /// If not provided, uses the instance's default [iosOptions].
  ///
  /// The scanner behavior is controlled by the platform-specific options:
  /// - On Android: Uses provided [androidOptions] or instance defaults
  /// - On iOS: Uses provided [iosOptions] or instance defaults
  /// - Throws [UnsupportedError] on unsupported platforms
  ///
  /// Returns a [Future] that completes with a list of [DocScanKitResult] objects,
  /// each containing the file path and type (JPEG or PDF) of the scanned content.
  ///
  /// The format of results depends on the [DocScanKitFormat] setting:
  /// - [DocScanKitFormat.images]: Returns individual JPEG image files
  /// - [DocScanKitFormat.document]: Returns a single PDF file with all pages
  ///
  /// Throws [PlatformException] if the scanner fails to initialize or
  /// if camera permissions are not granted.
  /// Throws [UnsupportedError] if called on an unsupported platform.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   // Use default options
  ///   final results = await docScanKit.scanner();
  ///   
  ///   // Or override options for this call
  ///   final customResults = await docScanKit.scanner(
  ///     androidOptions: DocScanKitOptionsAndroid(pageLimit: 5),
  ///     iosOptions: DocScanKitOptionsIOS(compressionQuality: 0.5),
  ///   );
  ///   
  ///   for (final result in results) {
  ///     print('Scanned ${result.type.name}: ${result.path}');
  ///   }
  /// } catch (e) {
  ///   print('Scanning failed: $e');
  /// }
  /// ```
  Future<List<DocScanKitResult>> scanner({
    DocScanKitOptionsAndroid? androidOptions,
    DocScanKitOptionsIOS? iosOptions,
  }) {
    final DocScanKitOptions options;

    if (Platform.isAndroid) {
      options = androidOptions ?? this.androidOptions;
    } else if (Platform.isIOS) {
      options = iosOptions ?? this.iosOptions;
    } else {
      throw UnsupportedError('Unsupported platform');
    }

    return DocScanKitPlatform.instance.scanner(options);
  }

  /// Performs Optical Character Recognition (OCR) on the provided image bytes.
  ///
  /// This method uses platform-specific text recognition capabilities to extract
  /// text content from image data. The image should contain readable text for
  /// optimal results.
  ///
  /// [imageBytes] - The raw bytes of the image file (JPEG, PNG, etc.)
  ///
  /// Returns a [Future] that completes with the recognized text as a [String].
  /// If no text is found or recognition fails, returns an empty string.
  ///
  /// The accuracy of text recognition depends on:
  /// - Image quality and resolution
  /// - Text clarity and font size
  /// - Lighting conditions when the image was captured
  /// - Language of the text (platform-dependent support)
  ///
  /// Example:
  /// ```dart
  /// final imageBytes = await File('document.jpg').readAsBytes();
  /// final recognizedText = await docScanKit.recognizeText(imageBytes);
  /// print('Extracted text: $recognizedText');
  /// ```
  Future<String> recognizeText(final List<int> imageBytes) =>
      DocScanKitPlatform.instance.recognizeText(imageBytes);

  /// Scans and decodes QR codes from the provided image bytes.
  ///
  /// This method analyzes the image data to detect and decode any QR codes
  /// present in the image. It can handle various QR code formats and sizes.
  ///
  /// [imageBytes] - The raw bytes of the image file containing QR code(s)
  ///
  /// Returns a [Future] that completes with the decoded QR code content as a [String].
  /// If no QR code is found or decoding fails, returns an empty string.
  ///
  /// For optimal QR code detection:
  /// - Ensure the QR code is clearly visible and not distorted
  /// - Provide adequate contrast between the code and background
  /// - Avoid excessive blur or low resolution images
  ///
  /// Example:
  /// ```dart
  /// final imageBytes = await File('qr_code.jpg').readAsBytes();
  /// final qrContent = await docScanKit.scanQrCode(imageBytes);
  /// if (qrContent.isNotEmpty) {
  ///   print('QR Code content: $qrContent');
  /// } else {
  ///   print('No QR code found');
  /// }
  /// ```
  Future<String> scanQrCode(final List<int> imageBytes) =>
      DocScanKitPlatform.instance.scanQrCode(imageBytes);

  /// Releases any resources and closes active scanner sessions.
  ///
  /// This method should be called when the DocScanKit instance is no longer needed,
  /// particularly on Android where it helps free up ML Kit resources and prevents
  /// memory leaks.
  ///
  /// On iOS, this method completes immediately as resources are managed automatically.
  /// On Android, it properly disposes of the ML Kit document scanner and related resources.
  ///
  /// It's recommended to call this method in the dispose() method of your widget
  /// or when your app is shutting down.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void dispose() {
  ///   docScanKit.close();
  ///   super.dispose();
  /// }
  /// ```
  Future<void> close() => DocScanKitPlatform.instance.close();
}
