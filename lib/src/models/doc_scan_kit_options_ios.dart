import 'dart:ui';

import 'package:doc_scan_kit/src/models/doc_scan_kit_options.dart';
import 'package:doc_scan_kit/src/models/modal_presentation_style_ios.dart';

/// iOS-specific configuration options for the document scanner.
///
/// This class extends [DocScanKitOptions] to provide iOS-specific settings
/// that control the behavior of Apple's VNDocumentCameraViewController.
///
/// These options allow customization of the scanner presentation style,
/// image compression quality, and UI appearance on iOS devices.
///
/// Example usage:
/// ```dart
/// final iosOptions = DocScanKitOptionsIOS(
///   format: DocScanKitFormat.document,
///   modalPresentationStyle: ModalPresentationStyleIOS.overFullScreen,
///   compressionQuality: 0.8,
///   color: Colors.blue,
/// );
/// ```
class DocScanKitOptionsIOS extends DocScanKitOptions {
  /// Creates iOS-specific scanner options with the given configuration.
  ///
  /// [format] - Output format for scanned documents (inherited from parent).
  /// [modalPresentationStyle] - How the scanner view controller is presented.
  /// [compressionQuality] - JPEG compression quality for scanned images.
  /// [color] - Tint color for scanner UI elements.
  ///
  /// Throws [AssertionError] if [compressionQuality] is not between 0.0 and 1.0.
  const DocScanKitOptionsIOS({
    super.format,
    this.modalPresentationStyle = ModalPresentationStyleIOS.overFullScreen,
    this.compressionQuality = 1.0,
    this.color,
  }) : assert(
          !(compressionQuality > 1.0 || compressionQuality < 0.0),
          'The compression quality value must be between 0.0 and 1.0',
        );

  /// The modal presentation style for the document scanner view controller.
  ///
  /// This property determines how the scanner interface is presented to the user:
  /// - [ModalPresentationStyleIOS.automatic]: System chooses the best style
  /// - [ModalPresentationStyleIOS.overFullScreen]: Covers the entire screen
  /// - [ModalPresentationStyleIOS.currentContext]: Presented over current context
  /// - [ModalPresentationStyleIOS.popover]: Presented in a popover (iPad)
  ///
  /// Default value: [ModalPresentationStyleIOS.overFullScreen]
  ///
  /// The presentation style affects the visual transition and how the scanner
  /// appears relative to the presenting view controller.
  final ModalPresentationStyleIOS modalPresentationStyle;

  /// JPEG compression quality for scanned images.
  ///
  /// This property controls the quality vs. file size trade-off for scanned images:
  /// - 0.0: Maximum compression, smallest file size, lowest quality
  /// - 1.0: No compression, largest file size, highest quality
  ///
  /// Valid range: 0.0 to 1.0 (inclusive)
  /// Default value: 1.0 (no compression)
  ///
  /// Lower values result in smaller file sizes but may reduce image quality.
  /// This setting applies to both individual image files and images within PDF documents.
  final double compressionQuality;

  /// Tint color applied to scanner UI elements and document detection overlay.
  ///
  /// This property customizes the appearance of interactive elements in the scanner:
  /// - Navigation bar buttons and controls
  /// - Document detection overlay borders
  /// - Action buttons and indicators
  ///
  /// If null, the system default tint color is used.
  ///
  /// **Important:** Setting the alpha channel to 0 will make buttons fully transparent,
  /// which may render them unusable. Ensure adequate visibility for user interaction.
  final Color? color;

  /// Serializes these iOS options to a JSON map for native communication.
  ///
  /// This method converts all iOS-specific configuration options into a
  /// map format that can be sent to the native iOS implementation through
  /// method channels.
  ///
  /// Returns a [Map<String, dynamic>] containing:
  /// - 'format': The output format as a string name
  /// - 'modalPresentationStyle': The presentation style as a string name
  /// - 'compressionQuality': The compression quality as a double (0.0-1.0)
  /// - 'color': The tint color as an array of RGBA values, or empty array if null
  @override
  Map<String, dynamic> toJson() => {
        'format': format.name,
        'modalPresentationStyle': modalPresentationStyle.name,
        'compressionQuality': compressionQuality,
        'color': color != null ? [color?.r, color?.g, color?.b, color?.a] : [],
      };
}
