import 'package:doc_scan_kit/src/doc_scan_kit_method_channel.dart';
import 'package:doc_scan_kit/src/models/doc_scan_kit_options.dart';
import 'package:doc_scan_kit/src/models/doc_scan_kit_result.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Abstract base class for platform-specific implementations of DocScanKit.
///
/// This class defines the interface that platform-specific implementations
/// must implement. It uses the plugin_platform_interface pattern to ensure
/// that platform implementations are properly verified and registered.
///
/// Platform implementations should extend this class and implement all
/// abstract methods to provide native functionality for document scanning,
/// text recognition, and QR code scanning.
abstract class DocScanKitPlatform extends PlatformInterface {
  /// Constructs a [DocScanKitPlatform] with the required verification token.
  ///
  /// This constructor is used by platform implementations to ensure proper
  /// registration with the plugin_platform_interface system.
  DocScanKitPlatform() : super(token: _token);

  /// Verification token used to ensure platform implementations are properly registered.
  static final _token = Object();

  /// The current platform implementation instance.
  ///
  /// Defaults to [DocScanKitMethodChannel] which provides method channel
  /// communication with native platform code.
  static late DocScanKitPlatform _instance;

  /// The default instance of [DocScanKitPlatform] to use for all operations.
  ///
  /// This getter returns the currently registered platform implementation.
  /// By default, it returns [DocScanKitMethodChannel], but can be overridden
  /// by platform-specific plugins or for testing purposes.
  static DocScanKitPlatform get instance => _instance;

  /// Sets the platform implementation instance.
  ///
  /// Platform-specific implementations should call this setter with their own
  /// platform-specific class that extends [DocScanKitPlatform] when they
  /// register themselves.
  ///
  /// The [instance] must be a valid implementation that passes token verification.
  ///
  /// Throws [AssertionError] if the instance doesn't have the correct verification token.
  static set instance(DocScanKitPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Launches the native document scanner and returns scan results.
  ///
  /// This method must be implemented by platform-specific classes to provide
  /// native document scanning functionality. The behavior should match the
  /// platform's native document scanning capabilities.
  ///
  /// [options] - Platform-specific configuration options that control scanner behavior.
  ///
  /// Returns a [Future] that completes with a list of [DocScanKitResult] objects
  /// representing the scanned documents.
  ///
  /// Should throw [PlatformException] if scanning fails or permissions are denied.
  Future<List<DocScanKitResult>> scanner(final DocScanKitOptions options);

  /// Performs text recognition on the provided image bytes.
  ///
  /// Platform implementations should use native OCR capabilities to extract
  /// text from the image data.
  ///
  /// [imageBytes] - Raw bytes of the image file to process.
  ///
  /// Returns a [Future] that completes with the recognized text as a [String].
  /// Should return an empty string if no text is found or recognition fails.
  Future<String> recognizeText(final List<int> imageBytes);

  /// Scans for QR codes in the provided image bytes.
  ///
  /// Platform implementations should use native barcode/QR code detection
  /// capabilities to decode QR codes from the image data.
  ///
  /// [imageBytes] - Raw bytes of the image file containing QR code(s).
  ///
  /// Returns a [Future] that completes with the decoded QR code content as a [String].
  /// Should return an empty string if no QR code is found or decoding fails.
  Future<String> scanQrCode(final List<int> imageBytes);

  /// Releases platform-specific resources and closes active sessions.
  ///
  /// Platform implementations should override this method to properly dispose
  /// of any native resources, particularly on Android where ML Kit resources
  /// need explicit cleanup.
  ///
  /// Returns a [Future] that completes when cleanup is finished.
  Future<void> close();
}
